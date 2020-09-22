#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal

function strings.to_lowercase {
    __verify_nr_args "$#" 1 strings.to_lowercase
    local string
    string="$1"
    echo "${string,,}"
}

function strings.to_uppercase {
    __verify_nr_args "$#" 1 strings.to_uppercase
    local string
    string="$1"
    echo "${string^^}"
}

function strings.capitalize {
    __verify_nr_args "$#" 1 strings.to_capitalize
    local string
    string="$1"
    echo "${string^}"
}


function strings.replace_char_with {
    __verify_nr_args "$#" 3 strings.replace_char_with
    local string char replacement
    string="$1"
    char="$2"
    replacement="$3"
    echo "${string//$char/$replacement}"
}

function strings.split_by_char {
    __verify_nr_args "$#" 2 strings.split_by_char
    local -a result
    local string char
    result=()
    string="$1"
    char="$2"
    for value in $(strings.replace_char_with "$string" "$char" " ")
    do
        result+=("$value")
    done
    echo "${result[@]}"
}

function strings.contains_string_sensitive {
    __verify_nr_args "$#" 2 strings.contains_string_sensitive
    local result string search
    string="$1"
    search="$2"
    if [[ "$string" =~ ^.*"$search".*$ ]]
    then
        result=1
    else
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function strings.contains_string_insensitive {
    __verify_nr_args "$#" 2 strings.contains_string_insensitive
    strings.contains_string_sensitive "$(strings.to_lowercase "$1")" "$(strings.to_lowercase "$1")"
}