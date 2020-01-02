#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

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