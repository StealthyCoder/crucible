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

function maps.put {
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
    maps.put "$1" "$2" "$3"
}

function maps.put_all {
    if __verify_if_arg_is_map "$1"
    then
        if [ "$(( $# % 2 ))" -eq 0 ]
        then
            logging.error "Arguments to maps.add_all should be <map> [<key> <value>]"
            exit 1
        fi
        local arr key value print export_name
        if __check_if_arg_is_local_map "$1"
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

function maps.merge {
    if __verify_if_arg_is_map "$1"
    then
        if __verify_if_arg_is_map "$2"
        then
            local src target print
            print="$(declare -p "$1" | sed -e "s/declare -Ax $1=/declare -A src=/" )"
            eval "$print"
            print="$(declare -p "$2" | sed -e "s/declare -Ax $2=/declare -A target=/" )"
            eval "$print"
            for key in "${!target[@]}"
            do
                src+=(["$key"]="${target[$key]}")
            done
            print="$(declare -p src | sed -e "s/declare -A src=/declare -Agx $1=/" )"
            eval "$print"
        fi
    fi
}

function maps.get {
    __verify_nr_args "$#" 2 maps.get
    if __verify_if_arg_is_map "$1"
    then
        local arr print
        if __check_if_arg_is_local_map "$1"
        then
            print="$(declare -p "$1" | sed -e "s/declare -A $1=/declare -A arr=/" )"
        else
            print="$(declare -p "$1" | sed -e "s/declare -Ax $1=/declare -A arr=/" )"
        fi
        eval "$print"
        echo "${arr[$2]}"
    fi
}

function maps.remove {
    __verify_nr_args "$#" 2 maps.remove
    if __verify_if_arg_is_map "$1"
    then
        local arr print
        if __check_if_arg_is_local_map "$1"
        then
            print="$(declare -p "$1" | sed -e "s/declare -A $1=/declare -A arr=/" )"
        else
            print="$(declare -p "$1" | sed -e "s/declare -Ax $1=/declare -A arr=/" )"
        fi
        eval "$print"
        unset arr["$2"]
        print="$(declare -p arr | sed -e "s/declare -A arr=/declare -Agx $1=/" )"
        declare -p arr
        eval "$print"
    fi
}

function maps.values {
    if __verify_if_arg_is_map "$1"
    then

        local arr print
        
        if __check_if_arg_is_local_map "$1"
        then
            print="$(declare -p "$1" | sed -e "s/declare -A $1=/declare -A arr=/" )"
        else
            print="$(declare -p "$1" | sed -e "s/declare -Ax $1=/declare -A arr=/" )"
        fi
        eval "$print"
        echo "${arr[@]}"
    fi
}

function maps.keys {
    if __verify_if_arg_is_map "$1"
    then

        local arr print
        
        if __check_if_arg_is_local_map "$1"
        then
            print="$(declare -p "$1" | sed -e "s/declare -A $1=/declare -A arr=/" )"
        else
            print="$(declare -p "$1" | sed -e "s/declare -Ax $1=/declare -A arr=/" )"
        fi
        eval "$print"
        echo "${!arr[@]}"
    fi
}

function maps.entries {
    if __verify_if_arg_is_map "$1"
    then

        local arr print
        
        if __check_if_arg_is_local_map "$1"
        then
            print="$(declare -p "$1" | sed -e "s/declare -A $1=/declare -A arr=/" )"
        else
            print="$(declare -p "$1" | sed -e "s/declare -Ax $1=/declare -A arr=/" )"
        fi
        eval "$print"
        for key in "${!arr[@]}"
        do
            echo "$key,${arr[$key]}"
        done
    fi
}

function maps.contains_key {
    __verify_nr_args "$#" 2 maps.contains_key
    if __verify_if_arg_is_map "$1"
    then
        local keys
        keys="$(maps.keys "$1")"
        if [ "$(echo "$keys" | grep -c "$2" )" -ge 1 ]
        then
            return 0 
        fi
        return 1
    fi
}

function maps.contains_value {
    __verify_nr_args "$#" 2 maps.contains_value
    if __verify_if_arg_is_map "$1"
    then
        local values
        values="$(maps.values "$1")"
        if [ "$(echo "$values" | grep -c "$2" )" -ge 1 ]
        then
            return 0 
        fi
        return 1
    fi
}