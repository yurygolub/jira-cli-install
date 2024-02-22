function Install-JiraCli
{
    param (
        [string]$destination
    )

    $url = 'https://github.com/ankitpokhrel/jira-cli/releases/latest'
    $redirected = Get-RedirectedUrl $url

    $tagName = Split-Path $redirected -Leaf
    $archive = "jira_$($tagName.Substring(1))_windows_x86_64.zip"

    if (!(Test-Path -Path $archive))
    {
        $downloadUrl = "https://github.com/ankitpokhrel/jira-cli/releases/download/${tagName}/${archive}"

        Write-Host "Downloading `'$archive`' from `'${downloadUrl}`'"
        Invoke-WebRequest $downloadUrl -OutFile $archive
    }

    Write-Host "Expanding `'$archive`' to `'${destination}`'"
    Expand-Archive $archive -DestinationPath $destination -Force
    Remove-Item $archive
}

$ErrorActionPreference = "Stop"

$jiraCommand = Get-Command -ErrorAction Ignore -Type Application jira
if ($jiraCommand)
{
    $installationPaths = (Get-Item $jiraCommand.Path).Directory.Parent.FullName
    if ($installationPaths -isnot [string])
    {
        $jiraPath = $installationPaths[0]
    }
    else
    {
        $jiraPath = $installationPaths
    }

    Write-Warning "jira-cli already installed: '${jiraPath}'"

    $question = 'Do you want to update it?'
    $choices = '&Yes', '&No'

    $reinstall = $Host.UI.PromptForChoice($null, $question, $choices, 1)
    if ($reinstall -eq 0)
    {
        Install-JiraCli $jiraPath
    }

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

    $defaultPath = $env:ProgramFiles
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
        Write-Verbose "Found redirected url '$($resp.ResponseUri)'"
        $result = $resp.ResponseUri.OriginalString
    }
    else
    {
        Write-Warning 'No redirected url was found, returning given url.'
        $result = $url
    }

    $resp.Dispose()

    return $result
}

$jiraBin = Join-Path $destPath -ChildPath 'bin'

if (!(Test-Path -Path $jiraBin))
{
    Install-JiraCli $destPath
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

function Add-ForSpecifiedPath
{
    param (
        [Parameter(Mandatory = $true)]
        [EnvironmentVariableTarget]$variableTarget
    )

    $currentPath = [Environment]::GetEnvironmentVariable('Path', $variableTarget)
    if (!($currentPath -split ';' -contains $jiraBin))
    {
        $question = "Do you want to add `'${jiraBin}`' to Path?"
        $choices = '&Yes', '&No'

        $addToPath = $Host.UI.PromptForChoice($null, $question, $choices, 1)
        if ($addToPath -eq 0)
        {
            [Environment]::SetEnvironmentVariable('Path', $currentPath + ";${jiraBin}", $variableTarget)

            $env:Path = [System.Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) + ";" + [System.Environment]::GetEnvironmentVariable('Path',[EnvironmentVariableTarget]::User)
        }
    }
}

if ($choice -eq 0)
{
    Add-ForSpecifiedPath Machine
}
elseif ($choice -eq 1)
{
    Add-ForSpecifiedPath User
}

Write-Host 'Installation successfull'
