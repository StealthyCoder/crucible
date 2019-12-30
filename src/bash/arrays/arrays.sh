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

function arrays.add {
    __verify_nr_args "$#" 2 arrays.add
    __verify_if_arg_is_array "$1"
    local arr element print
    print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
    eval "$print"
    element="$2"        
    arr+=("$element")    
    print="$(declare -p arr | sed -e "s/declare -a arr=/export $1=/" )"
    eval "$print"
}

function arrays.push {
    arrays.add "$1" "$2"
}

function arrays.add_all {
    __verify_if_arg_is_array "$1"
    local arr element print export_name
    print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
    eval "$print"
    export_name="$1"
    shift
    while test $# -gt 0
    do
        element="$1"
        arr+=("$element")
        shift
    done
    
    print="$(declare -p arr | sed -e "s/declare -a arr=/export $export_name=/" )"
    eval "$print"
}

function arrays.concat {
    __verify_if_arg_is_array "$1"
    __verify_if_arg_is_array "$2"
    local src target print
    print="$(declare -p "$1" | sed -e "s/declare -ax $1=/src=/" )"
    eval "$print"
    print="$(declare -p "$2" | sed -e "s/declare -ax $2=/target=/" )"
    eval "$print"
    for element in "${target[@]}"
    do
        src+=("$element")
    done
    print="$(declare -p src | sed -e "s/declare -a src=/export $1=/" )"
    eval "$print"
}

function arrays.get {
    __verify_nr_args "$#" 2 arrays.get
    __verify_if_arg_is_array "$1"
    local arr element print
    print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
    eval "$print"
    echo "${arr[$2]}"
}

function arrays.pop {
    __verify_if_arg_is_array "$1"

    local arr last element print size counter
    local -a target
    target=()
    print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
    eval "$print"
    if [ "${#arr[@]}" -le 0 ]
    then
        return 0
    fi

    last="${arr[-1]}"
    size="$(( ${#arr[@]} - 1 ))"
    counter=0
    while test "$counter" -ne "$size"
    do
        element="${arr[$counter]}"
        target+=("$element")
        counter="$((counter + 1))"
    done

    print="$(declare -p target | sed -e "s/declare -a target=/export $1=/" )"
    eval "$print"

    eval "export $2=$last"

}

function arrays.values {
    __verify_if_arg_is_array "$1"

    local arr print
    print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
    eval "$print"
    echo "${arr[@]}"
}

function arrays.entries {
     __verify_if_arg_is_array "$1"

    local arr print size counter
    print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
    eval "$print"
    if [ "${#arr[@]}" -le 0 ]
    then
        return 0
    fi

    size="$(( ${#arr[@]} ))"
    counter=0
    while test "$counter" -ne "$size"
    do
        echo "Index: $counter, Value: ${arr[$counter]}"
        counter="$((counter + 1))"
    done

}

function arrays.clear {
    __verify_if_arg_is_array "$1"
    arrays.transform_into_array "$1"
}

function __verify_nr_args {
    if [ "$#" -ne 3 ]
    then
        echo "Must pass three arguments to this function."
        echo " 1. Number of arguments gotten"
        echo " 2. Number of arguments expected"
        echo " 3. Name of the function"
        echo " Example: __verify_nr_args 1 1 arrays.dummy"
        exit 1
    fi
    if [ "$1" -ne "$2" ]
    then
        echo "Need exactly $2 arguments for $3, gotten only $1"
        exit 1
    fi
}

function __verify_if_arg_is_array {
    if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -ax\ "$1"= ]]
    then
        echo "Argument needs to be an array created by arrays.transform_into_array"
        return 1
    fi
    return 0
}