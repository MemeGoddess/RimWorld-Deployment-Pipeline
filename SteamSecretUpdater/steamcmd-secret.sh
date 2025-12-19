#!/bin/bash

function addSecret()
{
    local repo=$1
    if [[ -z "$repo" ]]; then
        echo "No repository specified. Usage: addSecret <repo>"
        return 1
    fi

    steamcmd +login $STEAM_USERNAME +quit
    verifySteam

    # Determine repository visibility
    isPrivate=$(gh repo view "$GH_USERNAME/$repo" --json isPrivate -q '.isPrivate' 2>/dev/null || gh api repos/$GH_USERNAME/$repo --jq '.private' 2>/dev/null || echo "unknown")
    if [[ "$isPrivate" == "true" ]]; then
        vis="private"
    elif [[ "$isPrivate" == "false" ]]; then
        vis="public"
    else
        vis="unknown"
    fi

    # Prompt for confirmation with warning
    echo
    echo "===================================================="
    if [ -t 1 ]; then
        printf "WARNING: You are about to add Steam secrets to the repository: \033[31m$GH_USERNAME/%s\033[0m\n" "$repo"
    else
        printf "WARNING: You are about to add Steam secrets to the repository: $GH_USERNAME/%s\n" "$repo"
    fi
    echo "Repository visibility: $vis"
    echo "This will grant full SteamCMD access to the Steam account '$STEAM_USERNAME' for actions run by that repository's workflows."
    echo "===================================================="
    echo ""
    read -r -p "Do you want to continue? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        return 1
    fi

    gh secret set STEAM_USERNAME -R "$GH_USERNAME/$repo" -b "$STEAM_USERNAME"
    gh secret set STEAM_CONFIG_VDF -R "$GH_USERNAME/$repo" < ~/Steam/config/config.vdf
}

function updateSecrets()
{
    steamcmd +login $STEAM_USERNAME +quit
    verifySteam

    gh repo list $GH_USERNAME --json name,description,isPrivate,isFork,updatedAt --limit 1000 | jq -r '.[] | [.name, .description, .isPrivate, .isFork, .updatedAt] | @tsv' | while IFS=$'\t' read -r RepoName Description Visibility IsFork Age; do
        echo
        echo "=== $RepoName ==="
        if secret_line=$(gh secret list -R "$GH_USERNAME/$RepoName" 2>/dev/null | awk '/^STEAM_CONFIG_VDF\t/{print $0; exit}'); then
            if [[ -z "${secret_line}" ]]; then
                echo "STEAM_CONFIG_VDF secret not found, skipping."
                continue
            fi
            updated_date=$(echo "$secret_line" | awk '{print $NF}')
            if updated_ts=$(date -d "$updated_date" +%s 2>/dev/null); then
                cutoff_ts=$(date -d "1 month ago" +%s)
                if [[ "$updated_ts" -lt "$cutoff_ts" ]]; then
                    echo "STEAM_CONFIG_VDF older than 1 month, updating..."
                    gh secret set STEAM_CONFIG_VDF -R "$GH_USERNAME/$RepoName" < ~/Steam/config/config.vdf
                else
                    echo "STEAM_CONFIG_VDF is up to date (updated $updated_date)"
                fi
            else
                echo "$RepoName: Could not parse updated date: $updated_date"
            fi
        fi
    done

}

function verifySteam()
{
    CONFIG_VDF="$HOME/Steam/config/config.vdf"

    if [ ! -f "$CONFIG_VDF" ]; then
        echo "Config file not found: $CONFIG_VDF" >&2
        exit 1
    fi

    if [ ! -r "$CONFIG_VDF" ]; then
        echo "Config file is not readable: $CONFIG_VDF" >&2
        exit 1
    fi

    # Ensure file has non-whitespace content
    if ! grep -q '[^[:space:]]' "$CONFIG_VDF"; then
        echo "Config file is empty or contains only whitespace: $CONFIG_VDF" >&2
        exit 1
    fi
}

function verifyEnv()
{
    if ! command -v gh &> /dev/null; then
        echo "gh CLI could not be found, please install it from https://cli.github.com/"
        exit 1
    fi
    if ! gh auth status &> /dev/null; then
        echo "gh CLI is not authenticated. Please run 'gh auth login' to authenticate."
        exit 1
    fi

    if ! command -v steamcmd &> /dev/null; then
        echo "steamcmd could not be found, please install it"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "jq could not be found, please install it from https://jqlang.org/download/"
        exit 1
    fi

    if [ -z "$STEAM_USERNAME" ]; then
        echo "STEAM_USERNAME environment variable is not set."
        exit 1
    fi

    if [ -z "$GH_USERNAME" ]; then
        echo "GH_USERNAME environment variable is not set."
        exit 1
    fi
}

verifyEnv

while [ "$1" != "" ]; do
    case $1 in
        -h | --help)
            printf "Usage: %s [OPTIONS]\n\n" "update-secret.sh"
            printf "Options:\n"
            printf "  -h, --help     Show this help message\n"
            printf "  -a, --add      Add STEAM_CONFIG_VDF secret to a specific $GH_USERNAME repo\n"
            printf "  -u, --update   Scan $GH_USERNAME repos and update STEAM_CONFIG_VDF if older than 1 month\n\n"
            printf "Example: ./update-secret.sh --add\n"
            exit
            ;;
        -a | --add )
            addSecret "$2"   
            exit
            ;;
        -u | --update ) 
            updateSecrets
            exit
            ;;
        * )
            echo "Invalid option: $1"
            exit 1
            ;;
    esac
    shift
done

printf "Usage: %s [OPTIONS]\n\n" "update-secret.sh"
printf "Options:\n"
printf "  -h, --help     Show this help message\n"
printf "  -a, --add      Add STEAM_CONFIG_VDF secret to a specific $GH_USERNAME repo\n"
printf "  -u, --update   Scan $GH_USERNAME repos and update STEAM_CONFIG_VDF if older than 1 month\n\n"
printf "Example: ./update-secret.sh --add\n"
exit