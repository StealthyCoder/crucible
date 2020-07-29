#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging

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
        local arr key value print
        if __check_if_arg_is_local_map "$1"
        then
            print="$(declare -p "$1" | sed -e "s/declare -A $1=/declare -A arr=/" )"
        else
            print="$(declare -p "$1" | sed -e "s/declare -Ax $1=/declare -A arr=/" )"
        fi
        eval "$print"
        key="$2"
        value="$3"
        arr+=(["$key"]="$value")
        print="$(declare -p arr | sed -e "s/declare -A arr=/declare -Agx $1=/" )"
        eval "$print"
    fi
}

function maps.push {
    maps.add "$1" "$2" "$3"
}

function maps.add_all {
    if __verify_if_arg_is_map "$1"
    then
        if [ "$(( $# % 2 ))" -eq 0 ]
        then
            logging.error "Arguments to maps.add_all should be <map> [<key> <value>]"
            exit 1
        fi
        local arr key value print export_name
        if __check_if_arg_is_local_array "$1"
        then
            print="$(declare -p "$1" | sed -e "s/declare -A $1=/declare -A arr=/" )"
        else
            print="$(declare -p "$1" | sed -e "s/declare -Ax $1=/declare -A arr=/" )"
        fi
        eval "$print"
        export_name="$1"
        shift
        while test $# -gt 0
        do
            key="$1"
            shift
            value="$1"
            arr+=(["$key"]="$value")
            shift
        done        
        print="$(declare -p arr | sed -e "s/declare -A arr=/declare -Agx $export_name=/" )"
        eval "$print"
    fi
}