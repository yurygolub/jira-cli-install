# Install jira-cli for Windows

This repository contains script to install [jira-cli](https://github.com/ankitpokhrel/jira-cli) on Windows

The script offers to install *jira-cli* for all users or for current user.

Also you will be prompted to add  jira-cli to Path and according to what you chose earlier, it will add it to system or local path. This script exports *JIRA_API_TOKEN* environment variable the same way if it is not already set. **And it does not modify registry**

## Install

* Create Personal Access Token in your jira account

* Set execution policy

    ```sh
    Set-ExecutionPolicy Bypass -Scope Process -Force
    ```

* Run script

    ```sh
    .\jira-cli-install.ps1
    ```

* Check installation

    ```sh
    jira
    ```

## Configure

Run this to generate config file

```sh
jira init
```

Installation type: **Local**

Authentication type: **bearer**

Link to Jira server: `your-link`

Login username: `your-username`

Then select default project and default board

## Test installation

You can view issues of your default project

```sh
jira issue list
```
