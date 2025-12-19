# Steam Secret Updater
At the heart of this pipeline is SteamCMD, it's used to upload to the workshop. The problem is that SteamCMD doesn't have an API key system or anything like that accessible to the public. You *could* use your password for it, but that's more dangerous, and doesn't work with 2FA, so I don't support it in the pipeline. 

The way we handle this is by using SteamCMD's config.vdf file, which is generated when you first log in to SteamCMD, and then used to not prompt for password/2FA code when you next log in. This however does have an expiry on it, which is where this tool comes in.

An easy way to keep the tokens up to date is running this container, which will check every hour for any token that is older than 1 month, and then update it. It logs into SteamCMD beforehand as well, refreshing your token locally.

This works perfectly fine in WSL.

## Warning
Please read the entire README, there are quite a few things you need to do to set this up. But once it's set up, there shouldn't be anything you need to do to maintain it.

This does place a token for your Steam account in the secrets for a repo. This obviously can be dangerous if someone gets their hands on that, it would give them full access to your account via SteamCMD. Github does a reasonably good job at preventing secrets from leaking, but still. If you're worried, a good alternative is to create a 2nd account, add it as a contributor to your mods, and log in with that instead.

## Setup
Clone or download this folder, then update the STEAM_USERNAME and GH_USERNAME. Make sure you've logged in before with both `gh` (Github's CLI tool)  and `SteamCMD` on your machine, as the container reuses the config files from that. You may need to update the `config/config.vdf` path if it's not correct.

### SteamCMD
First we'll set up SteamCMD, you'll be prompted to enter your password, and do any extra 2FA stuff.
```bash
steamcmd +login $STEAM_USERNAME +quit
```
It's a good idea to check where SteamCMD is keeping your config, as it's different for each distro. When SteamCMD loads up, it'll say something like this, you can find the Config folder in that Steam folder. You'lll probably need to update the path in `docker-compose.yml`

`Logging directory: '/some/path/to/steamcmd/Steam/logs`

This means the path would be `/some/path/to/steamcmd/Steam/config/config.vdf`

### Github
Next we have to authenticate with Github, you can log in via your browser, so this is very easy.
```bash
gh auth login
```
Same as SteamCMD, the config location might be different than expected. You can find it by running this.

```bash
gh auth status
```
It'll show you the path for the hosts file, and we just want to mount the folder that's in. Should look something like this:

`✓ Logged in to github.com account X (~/.config/gh/hosts.yml)`
Which would make the right value `~/.config/gh`

### Starting the Container

Once you've done that, it's as simple as running it with docker compose.
```bash
docker compose up --build --detach
```

Or if you would like to update the tool
```bash
git pull
docker compose down && docker compose up --build --detach
```

## Add Secret to new Repo
Setting up a new repo for the pipeline is really easy with this tool as well. You can simply run this command, and it'll set up the secrets. This would add the `STEAM_USERNAME` and `STEAM_CONFIG_VDF` secrets to the `MemeGoddess/RimWorld-ReplaceStuff` repository

```bash
docker exec -it steam-secret-updater ./steamcmd-secret.sh -a RimWorld-ReplaceStuff
```