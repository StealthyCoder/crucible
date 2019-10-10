#!/usr/bin/env bash

function require {
    local local_crucible_version shared_crucible_version shared_location module_name
    local_crucible_version="$(grep 'version' .crucible | cut -d'=' -f 2)"
    shared_crucible_version="$( grep 'version' "$(grep 'shared_dir' .crucible | cut -d'=' -f 2)"/.crucible | cut -d'=' -f 2)"
    if [ "$local_crucible_version" != "$shared_crucible_version" ]
    then 
        echo "Versions out of sync. Please run crucible update."
        exit 1 
    fi
    if [ -z "$1" ]
    then 
        echo "Module to require has to be specified."
        exit 1
    fi
    shared_location="$(grep 'shared_dir' .crucible | cut -d'=' -f 2)/"
    module_name="$(echo "$1" | cut -d'/' -f 2)"
    if [ -f "$shared_location$module_name" ]
    then
        local module_version
        module_version="$(grep 'CRUCIBLE_VERSION' "$shared_location$module_name" | cut -d'=' -f 2 )"
        if [ "$module_version" != "$local_crucible_version" ]
        then 
            wget --no-cache -q -O "$shared_location$module_name" "https://raw.githubusercontent.com/StealthyCoder/crucible/mould/src/${1%.sh}.sh"
        fi
    else
        wget --no-cache -q -O "$shared_location$module_name" "https://raw.githubusercontent.com/StealthyCoder/crucible/mould/src/${1%.sh}.sh"
    fi
    # shellcheck disable=SC1090
    source "$shared_location$module_name"
}