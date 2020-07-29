#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require logging/logging


function __verify_nr_args {
    if [ "$#" -ne 3 ]
    then
        logging.info "Must pass three arguments to this function."
        logging.info " 1. Number of arguments gotten"
        logging.info " 2. Number of arguments expected"
        logging.info " 3. Name of the function"
        logging.info " Example: __verify_nr_args 1 1 arrays.dummy"
        exit 1
    fi
    if [ "$1" -ne "$2" ]
    then
        logging.error "Need exactly $2 arguments for $3, gotten only $1"
        exit 1
    fi
}

function __verify_if_arg_is_array {
    if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -ax\ "$1"= ]]
    then
        if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -a\ "$1" ]]
        then
            logging.error "Argument needs to be an array created by arrays.transform_into_array"
            logging.error "$(declare -p "$1")"
            return 1
        fi
    fi
    return 0
}

function __check_if_arg_is_local_array {
    if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -a\ "$1" ]]
    then
        return 1
    fi
    return 0
}

function __verify_arg_is_function {
    if [ "$(typeset -f | grep -c "$1 ()" )" -eq 0 ]
    then
        return 1
    fi
    return 0
}

function __verify_if_arg_is_map {
    if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -Ax\ "$1"= ]]
    then
        if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -A\ "$1" ]]
        then
            logging.error "Argument needs to be a map created by maps.transform_into_map"
            logging.error "$(declare -p "$1")"
            return 1
        fi
    fi
    return 0
}

function __check_if_arg_is_local_map {
    if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -A\ "$1" ]]
    then
        return 1
    fi
    return 0
}