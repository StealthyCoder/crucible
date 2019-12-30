#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

function arrays.transform_into_array {
    local -a arr
    local print
    arr=()
    print="$(declare -p arr | sed -e "s/declare -a arr=/export $1=/" )"
    eval "$print"
}

function arrays.add_to_array {
    if [ "$(__check_nr_args "$#" 2)" != "true" ]
    then
        echo "Need exactly two arguments for arrays.add_to_array"
        exit 1
    fi
    if [ "$(declare -p "$1" 2>/dev/null)" != "declare -ax $1=()" ]
    then
        echo "First argument needs to be an array created by arrays.transform_into_array"
        exit 1
    fi
    local arr element print
    print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
    eval "$print"
    element="$2"        
    arr+=("$element")    
    print="$(declare -p arr | sed -e "s/declare -a arr=/export $1=/" )"
    eval "$print"
}

function __check_nr_args {
    if [ "$#" -ne 2 ]
    then
        echo "Must pass two arguments to this function."
        echo "Error"
    fi
    if [ "$1" -ne "$2" ]
    then
        echo false
    else
        echo true
    fi
    
}