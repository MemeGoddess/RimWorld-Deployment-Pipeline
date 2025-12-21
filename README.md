# RimWorld Deployment Pipline
Contains a lot of useful Pipeline actions and workflows to automate parts of RimWorld modding. These are tools I've built over the years that I've been doing this, plus some advice to make things easier for modders.

## Setup
In the "Actions secrets and variables" tab (Your Repo -> Settings -> Secrets and variables -> Actions), add `STEAM_CONFIG_VDF` and `STEAM_USERNAME`. You can get the `STEAM_CONFIG_VDF` value by logging in to SteamCMD locally on your account, and then pasting the contents of the `config.vdf` SteamCMD saves. <b>This token expires over time</b>, I might publish my script to scan and update at some point though.

## Deploy to Workshop
This workflow builds the mod, does a bunch of cleanup, and then updates it on the Steam Workshop. It cannot publish a new mod or update version tags. 

<i>What I typically do to publish is deploy to staging, then upload that to the workshop.</i>

```yaml
name: RimWorld Deploy

on:
  push:
    branches:
      - main
      - master

jobs:
  rimworld-deploy:
      uses: MemeGoddess/RimWorld-Deployment-Pipeline/.github/workflows/deploy.yml@beta
      secrets: inherit
      with:
          # This is a private workshop ID that I use as staging
          # I highly recommend you have one as well
          # Only update after you've deployed to staging and confirmed it works
          workshopId: '3526439840' 
          
          # ex: 'Source/RimMod.csproj, ModCompat/X/X.csproj'
          # optional, will skip building if not provided
          ProjectFiles: 'Source/RimMod.csproj' 
```

## Build on PR close
Want to keep the debug version of your mod up to date in your main branch? This workflow will build all your changes, and do a `chore` commit to your main branch with all the mod assemblies. This won't trigger a deployment.

```yaml
name: Build and Commit to Main on PR Close

on:
    pull_request:
        types: [closed]
        branches:
        - main
        - master
        paths:
          - 'Source/**' # Include any other folders as well

permissions:
  contents: write

jobs:
  pr-closed-build:
    uses: MemeGodess/RimWorld-Deployment-Pipeline/.github/workflows/pr-closed.yml@beta
    with:
      ProjectFiles: 'Source/RimMod.csproj'
```