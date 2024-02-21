param(
    [ValidateRange(-1, 1)]
    [Int32]
    $Choice = -1
)

if (Get-Command -ErrorAction Ignore -Type Application jira) {
    Write-Warning 'jira-cli already installed'
    return
}

if ($Choice -eq -1) {
    $title = "This script will install jira-cli"
    $question = "How do you want to install it?"
    $choices = '&All users', '&Current user'

    $Choice = $Host.UI.PromptForChoice($title, $question, $choices, 1)
}

if ($Choice -eq 0) {
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        $currentShell = [System.AppDomain]::CurrentDomain.FriendlyName
        Start-Process $currentShell -WorkingDirectory $pwd "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Choice ${Choice}" -Verb RunAs
        exit
    }

    $defaultPath = 'c:\Program Files'
} elseif ($Choice -eq 1) {
    $defaultPath = "${env:USERPROFILE}\AppData\Local\"
}

if (!($inputPath = Read-Host "Input installation path. Default is [$defaultPath]")) {
    $inputPath = $defaultPath
}

if (!(Test-Path -Path $inputPath)) {
    Write-Warning "Invalid path `'${inputPath}`'"
    return
}

$destFolder = 'jira-cli'
$destPath = Join-Path $inputPath -ChildPath $destFolder

$title = "Latest version of jira-cli will be installed to `'${destPath}`'"
$question = 'Are you sure you want to proceed?'
$choices = '&Yes', '&No'

$proceedDecision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($proceedDecision -eq 1) {
    Write-Host 'Abort'
    return
}

function Get-RedirectedUrl {
    param(
        [Parameter(Mandatory = $true)]
        [uri]$url,
        [uri]$referer
    )

    $req = [Net.WebRequest]::CreateDefault($url)
    if ($referer) {
        $req.Referer = $referer
    }

    $resp = $req.GetResponse()

    if ($resp -and $resp.ResponseUri.OriginalString -ne $url) {
        Write-Verbose "Found redirected url '$($resp.ResponseUri)"
        $result = $resp.ResponseUri.OriginalString
    }
    else {
        Write-Warning "No redirected url was found, returning given url."
        $result = $url
    }

    $resp.Dispose()

    return $result
}

$jiraBin = Join-Path $destPath -ChildPath 'bin'

if (!(Test-Path -Path $jiraBin)) {
    $url = 'https://github.com/ankitpokhrel/jira-cli/releases/latest'
    $redirected = Get-RedirectedUrl $url

    $tagName = Split-Path $redirected -Leaf
    $version = $tagName.Substring(1)
    $archive = "jira_${version}_windows_x86_64.zip"

    if (!(Test-Path -Path $archive)) {
        $downloadUrl = "https://github.com/ankitpokhrel/jira-cli/releases/download/${tagName}/${archive}"

        Write-Host "Downloading `'$archive`' from `'${downloadUrl}`'"
        Invoke-WebRequest $downloadUrl -OutFile $archive
    }

    $null = New-Item -Path $destPath -ItemType Directory
    Expand-Archive $archive -DestinationPath $destPath
    Remove-Item $archive
}

$apiToken = Read-Host "Input api token" -AsSecureString

if ($Choice -eq 0) {
    [Environment]::SetEnvironmentVariable('JIRA_API_TOKEN', $apiToken, [EnvironmentVariableTarget]::Machine)
} elseif ($Choice -eq 1) {
    [Environment]::SetEnvironmentVariable('JIRA_API_TOKEN', $apiToken, [EnvironmentVariableTarget]::User)
}

$question = "Do you want to add ${jiraBin} to Path?"
$choices = '&Yes', '&No'

$addToPath = $Host.UI.PromptForChoice($null, $question, $choices, 1)
if ($addToPath -eq 0) {
    if ($Choice -eq 0) {
        $machinePath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
        if (!($machinePath -split ';' -contains $jiraBin)) {
            [Environment]::SetEnvironmentVariable('Path', $machinePath + ";${jiraBin}", [EnvironmentVariableTarget]::Machine)
        }
    } elseif ($Choice -eq 1) {
        $userPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)
        if (!($userPath -split ';' -contains $jiraBin)) {
            [Environment]::SetEnvironmentVariable('Path', $userPath + ";${jiraBin}", [EnvironmentVariableTarget]::User)
        }
    }

    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) + ";" + [System.Environment]::GetEnvironmentVariable('Path',[EnvironmentVariableTarget]::User)
}

Write-Host 'Installation successfull'
