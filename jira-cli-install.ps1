$ErrorActionPreference = "Stop"

if (Get-Command -ErrorAction Ignore -Type Application jira)
{
    Write-Warning 'jira-cli already installed'
    return
}

$title = "This script will install jira-cli"
$question = "How do you want to install it?"
$choices = '&All users', '&Current user'

$choice = $Host.UI.PromptForChoice($title, $question, $choices, 1)

if ($choice -eq 0)
{
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-Warning 'You have to run this script as admin'
        return
    }

    $defaultPath = 'c:\Program Files'
}
elseif ($choice -eq 1)
{
    $defaultPath = "${env:USERPROFILE}\AppData\Local\"
}

if (!($inputPath = Read-Host "Input installation path. Default is [$defaultPath]"))
{
    $inputPath = $defaultPath
}

if (!(Test-Path -Path $inputPath))
{
    Write-Warning "Invalid path `'${inputPath}`'"
    return
}

$destFolder = 'jira-cli'
$destPath = Join-Path $inputPath -ChildPath $destFolder

$title = "Latest version of jira-cli will be installed to `'${destPath}`'"
$question = 'Are you sure you want to proceed?'
$choices = '&Yes', '&No'

$proceedDecision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($proceedDecision -eq 1)
{
    Write-Host 'Abort'
    return
}

function Get-RedirectedUrl
{
    param(
        [Parameter(Mandatory = $true)]
        [uri]$url,
        [uri]$referer
    )

    $req = [Net.WebRequest]::CreateDefault($url)
    if ($referer)
    {
        $req.Referer = $referer
    }

    $resp = $req.GetResponse()

    if ($resp -and $resp.ResponseUri.OriginalString -ne $url)
    {
        Write-Verbose "Found redirected url '$($resp.ResponseUri)"
        $result = $resp.ResponseUri.OriginalString
    }
    else
    {
        Write-Warning "No redirected url was found, returning given url."
        $result = $url
    }

    $resp.Dispose()

    return $result
}

$jiraBin = Join-Path $destPath -ChildPath 'bin'

if (!(Test-Path -Path $jiraBin))
{
    $url = 'https://github.com/ankitpokhrel/jira-cli/releases/latest'
    $redirected = Get-RedirectedUrl $url

    $tagName = Split-Path $redirected -Leaf
    $version = $tagName.Substring(1)
    $archive = "jira_${version}_windows_x86_64.zip"

    if (!(Test-Path -Path $archive))
    {
        $downloadUrl = "https://github.com/ankitpokhrel/jira-cli/releases/download/${tagName}/${archive}"

        Write-Host "Downloading `'$archive`' from `'${downloadUrl}`'"
        Invoke-WebRequest $downloadUrl -OutFile $archive
    }

    $null = New-Item -Path $destPath -ItemType Directory
    Expand-Archive $archive -DestinationPath $destPath
    Remove-Item $archive
}

if (!($apiToken = Read-Host "Input api token. Press enter to get it from clipboard" -MaskInput))
{
    $apiToken = Get-Clipboard
}

$Env:JIRA_API_TOKEN = $apiToken

if ($choice -eq 0)
{
    [Environment]::SetEnvironmentVariable('JIRA_API_TOKEN', $apiToken, [EnvironmentVariableTarget]::Machine)
}
elseif ($choice -eq 1)
{
    [Environment]::SetEnvironmentVariable('JIRA_API_TOKEN', $apiToken, [EnvironmentVariableTarget]::User)
}

$question = "Do you want to add `'${jiraBin}`' to Path?"
$choices = '&Yes', '&No'

if ($choice -eq 0)
{
    $machinePath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
    if (!($machinePath -split ';' -contains $jiraBin))
    {
        $addToPath = $Host.UI.PromptForChoice($null, $question, $choices, 1)
        if ($addToPath -eq 0)
        {
            [Environment]::SetEnvironmentVariable('Path', $machinePath + ";${jiraBin}", [EnvironmentVariableTarget]::Machine)

            $env:Path = [System.Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) + ";" + [System.Environment]::GetEnvironmentVariable('Path',[EnvironmentVariableTarget]::User)
        }
    }
}
elseif ($choice -eq 1)
{
    $userPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)
    if (!($userPath -split ';' -contains $jiraBin))
    {
        $addToPath = $Host.UI.PromptForChoice($null, $question, $choices, 1)
        if ($addToPath -eq 0)
        {
            [Environment]::SetEnvironmentVariable('Path', $userPath + ";${jiraBin}", [EnvironmentVariableTarget]::User)

            $env:Path = [System.Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) + ";" + [System.Environment]::GetEnvironmentVariable('Path',[EnvironmentVariableTarget]::User)
        }
    }
}

Write-Host 'Installation successfull'
