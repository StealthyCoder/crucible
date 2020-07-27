#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require arrays/arrays

function text.split_by_char {
    __verify_nr_args "$#" 2 text.split_by_char
    local -a result
    for value in "${1//$2/ }"
    do
        arrays.add result "$value"
    done
    echo "$result"
}

function text.replace_char_with {
    __verify_nr_args "$#" 3 text.split_by_char
    echo "${1//$2/$3}"
}