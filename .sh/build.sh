#!/usr/bin/env bash

cd "$(dirname "$0")" || exit 1

declare -a shells

shells=("bash")


function ask {
	read -r -p "$1" var
	echo "$var"
}

function verify_version {
    local vCur
    for shell in "${shells[@]}"
    do
        vCur="$(grep 'CRUCIBLE_VERSION=' "../src/$shell/bin/crucible" | cut -d'=' -f2)"
        if [ "$NEW_VERSION" != "$vCur" ]
        then            
            echo "Inconsistent versions for shell $shell, please update crucible file src/$shell/bin/crucible."
            exit 1
        fi
    done
}

function fix_location {
    local location
    location="v$NEW_VERSION"
    for shell in "${shells[@]}"
    do
        sed -i -e "s/^CRUCIBLE_LOCATION=.*/CRUCIBLE_LOCATION=$location/" "../src/$shell/bin/crucible"
    done
}

function fix_versions {
    for shell in "${shells[@]}"
    do
        for f in ../src/"$shell"/**/*
        do
            sed -i -e "s/{CRUCIBLE_VERSION}/$NEW_VERSION/" "$f"
            sed -i -e "s/{CRUCIBLE_CREATED}/$(date +%s)/" "$f"
        done
    done
}

NEW_VERSION="$(ask 'What is the new version? ')"

verify_version
fix_location
fix_versions