#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require arrays/arrays

function text.replace_char_with {
    __verify_nr_args "$#" 3 text.replace_char_with
    echo "${1//$2/$3}"
}

function text.split_by_char {
    __verify_nr_args "$#" 2 text.split_by_char
    local -a result
    # shellcheck disable=SC2034
    result=()
    for value in $(text.replace_char_with "$1" "$2" " ")
    do
        arrays.add result "$value"
    done
    arrays.values result
}