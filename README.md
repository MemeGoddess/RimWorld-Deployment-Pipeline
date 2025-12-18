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
        uses: MemeGoddess/RimWorld-Deployment-Pipeline/.github/workflows/deploy.yml@main
        secrets: inherit
        with:
            # This is a private workshop ID that I use as staging
            # I highly recommend you have one as well
            workshopId: '3526439840' # Only update after you've deployed to staging and confirmed it works
            ProjectFiles: 'Source/RimMod.csproj' # ex: 'Source/RimMod.csproj, ModCompat/X/X.csproj'
```