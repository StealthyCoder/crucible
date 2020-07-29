#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal

function maps.transform_into_map {
    local -A arr
    local print
    arr=()
    print="$(declare -p arr | sed -e "s/declare -A arr=/declare -Agx $1=/" )"
    eval "$print"
}

function maps.add {
    __verify_nr_args "$#" 3 maps.add
    
    if __verify_if_arg_is_map "$1"
    then
        local arr element print
        if __check_if_arg_is_local_map "$1"
        then
            print="$(declare -p "$1" | sed -e "s/declare -A $1=/arr=/" )"
        else
            print="$(declare -p "$1" | sed -e "s/declare -Ax $1=/arr=/" )"
        fi
        eval "$print"
        key="$2"
        value="$3"
        arr+=(["$key"]="$value")
        print="$(declare -p arr | sed -e "s/declare -a arr=/declare -Agx $1=/" )"
        eval "$print"
    fi
}