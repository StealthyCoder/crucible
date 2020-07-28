#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.2.4
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1595942526
### CRUCIBLE META DATA ###

function require {
    local local_crucible_version shared_crucible_version shared_location module_name crucible_location slashes
    local_crucible_version="$(grep 'version' .crucible | cut -d'=' -f 2)"
    shared_crucible_version="$( grep 'version' "$(grep 'shared_dir' .crucible | cut -d'=' -f 2)"/.crucible | cut -d'=' -f 2)"
    crucible_location="$(grep 'location' .crucible | cut -d'=' -f 2)"
    if [ "$local_crucible_version" != "$shared_crucible_version" ]
    then 
        echo "Versions out of sync. Please run crucible update."
    fi
    if [ -z "$1" ]
    then 
        echo "Module to require has to be specified."
        exit 1
    fi
    shared_location="$(grep 'shared_dir' .crucible | cut -d'=' -f 2)/"
    slashes="$(echo "$1" | grep -o '/' | wc -l)"
    module_dir="$(echo "$1" | cut -d'/' -f1-"$slashes")"
    module_name="$(echo "$1" | cut -d'/' -f"$(("$slashes" + 1 ))")"
    module_file="$shared_location$module_dir/$module_name"
    if [ ! -d "$shared_location$module_dir" ]
    then
        mkdir -p "$shared_location$module_dir"
    fi
    if [ -f "$module_file" ]
    then
        local module_version
        module_version="$(grep 'CRUCIBLE_VERSION' "$module_file" | cut -d'=' -f 2 )"
        if [ "$module_version" != "$local_crucible_version" ]
        then 
            wget --no-cache -q -O "$module_file" "https://raw.githubusercontent.com/StealthyCoder/crucible/$crucible_location/src/bash/${1%.sh}.sh"
        fi
    else
        wget --no-cache -q -O "$module_file" "https://raw.githubusercontent.com/StealthyCoder/crucible/$crucible_location/src/bash/${1%.sh}.sh"
    fi
    # shellcheck disable=SC1090
    source "$module_file"
}