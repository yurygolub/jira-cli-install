# Install jira-cli for Windows

## Install

Create Personal Access Token in your jira account

Set execution policy

```sh
Set-ExecutionPolicy Bypass -Scope Process -Force
```

Run script

```sh
.\jira-cli-install.ps1
```

Check installation

```sh
jira
```

## Configure

Run this to generate config file

```sh
jira init
```

Installation type: Local

Authentication type: bearer

Link to Jira server: `your-link`

Login username: `your-username`

Then select default project and default board
