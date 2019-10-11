#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

function arrays.get_array {
    local arr 
    arr=()
    echo "${arr[@]}"
}

function arrays.transform_into_array {
    declare -a "$1"
}

function arrays.add_to_array {
    local arr element print
    print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
    eval "$print"
    element="$2"        
    arr+=("$element")    
    print="$(declare -p arr | sed -e "s/declare -a arr=/export $1=/" )"
    eval "$print"
}