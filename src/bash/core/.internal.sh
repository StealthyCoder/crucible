#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.2.6
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1600721972
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
    if [ "$1" -gt "$2" ]
    then
        logging.warning "Need exactly $2 arguments for $3, gotten $1."
        logging.warning "The surplus will not be used."
    elif [ "$1" -ne "$2" ]
    then
        logging.error "Need exactly $2 arguments for $3, gotten $1."
        exit 1
    fi
}

function __get_operator {
    __verify_nr_args "$#" 1 __get_operator
    local -A operators
    operators=()
    
    operators+=(["<"]="-lt")
    operators+=(["<="]="-le")
    operators+=([">"]="-gt")
    operators+=([">="]="-ge")
    operators+=(["=="]="-eq")
    operators+=(["!="]="-ne")
    if [ ! ${operators[$1]+_} ]
    then
        logging.error "Argument needs to be >,>=,<,<=,==,!= was $1"
    fi
    echo "${operators[$1]}"
}


function __to_boolean {
    __verify_nr_args "$#" 3 __to_boolean
    local operator result
    operator=$(__get_operator "$2")
    if [ "$operator" == "-lt" ]
    then
        result=$(if [[ "$1" -lt "$3" ]]; then echo 1; else echo 0; fi)
    elif [ "$operator" == "-le" ]
    then
        result=$(if [[ "$1" -le "$3" ]]; then echo 1; else echo 0; fi)
    elif [ "$operator" == "-gt" ]
    then
        result=$(if [[ "$1" -gt "$3" ]]; then echo 1; else echo 0; fi)
    elif [ "$operator" == "-ge" ]
    then
        result=$(if [[ "$1" -ge "$3" ]]; then echo 1; else echo 0; fi)
    elif [ "$operator" == "-eq" ]
    then
        result=$(if [[ "$1" -eq "$3" ]]; then echo 1; else echo 0; fi)
    elif [ "$operator" == "-ne" ]
    then
        result=$(if [[ "$1" -ne "$3" ]]; then echo 1; else echo 0; fi)
    fi
   
    if [[ "$result" -eq 1 ]]
    then
        true
    else 
        false
    fi
}

function __verify_if_arg_is_array {
    local result
    result=1
    if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -ax\ "$1"= ]]
    then
        if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -a\ "$1" ]]
        then
            logging.error "Argument needs to be an array created by arrays.transform_into_array"
            logging.error "$(declare -p "$1")"
            result=0
        fi
    fi
    __to_boolean "$result" "==" 1
}

function __check_if_arg_is_local_array {
    local result
    result=1
    if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -a\ "$1" ]]
    then
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function __verify_arg_is_function {
    local result
    result=1
    if [ "$(typeset -f | grep -c "$1 ()" )" -eq 0 ]
    then
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function __verify_if_arg_is_map {
    local result
    result=1
    if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -Ax\ "$1"= ]]
    then
        if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -A\ "$1" ]]
        then
            logging.error "Argument needs to be a map created by maps.transform_into_map"
            logging.error "$(declare -p "$1")"
            result=0
        fi
    fi
    __to_boolean "$result" "==" 1
}

function __check_if_arg_is_local_map {
    local result
    result=1
    if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -A\ "$1" ]]
    then
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function __verify_arg_is_valid_perm {
    local result
    result=1
    if [[ ! "$1" =~ [ugoa]*([-+=]([rwxXst]*|[ugo]))+|[-+=][0-7]+ ]]
    then 
        result=0
    fi
    if [[ "$1" =~ [0-7]{4} ]]
    then
        result=1
    fi
    __to_boolean "$result" "==" 1
}

function __is_root {
  local result
  if [ "$EUID" -eq 0 ]
  then
    result=1
  else
    result=0
  fi
  __to_boolean "$result" "==" 1
}

function __sudo {
  local sudo_result doas_result
  command -v sudo >/dev/null 2>&1
  sudo_result=$?
  command -v doas >/dev/null 2>&1
  doas_result=$?
  if __to_boolean "$sudo_result" "==" 0
  then
    sudo "$@"
  elif __to_boolean "$doas_result" "==" 0
  then
   doas "$@"
  elif __is_root
  then
    "$@"
  else
    local args
    args=""
    logging.error "No sudo or doas installed, cannot run this command:"
    for i in "$@"
    do 
      args+="$i "
    done
    logging.error "$args"
  fi
}
