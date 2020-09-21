#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.2.6
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1600721972
### CRUCIBLE META DATA ###

require logging/.internal

function logging.info {
    if [ "$(__check_log_level "$(logging.level.info)")" -ne 0 ]
    then
        _format "$(logging.level.info)" "$1"
    fi
    
}

function logging.debug {
    if [ "$(__check_log_level "$(logging.level.debug)")" -ne 0 ]
    then
        _format "$(logging.level.debug)" "$1"
    fi
}

function logging.warning {
    if [ "$(__check_log_level "$(logging.level.warning)")" -ne 0 ]
    then
        _format "$(logging.level.warning)" "$1"
    fi
}

function logging.error {
    if [ "$(__check_log_level "$(logging.level.error)")" -ne 0 ]
    then
        _format "$(logging.level.error)" "$1"
    fi
}

function logging.success {
    if [ "$(__check_log_level "$(logging.level.success)")" -ne 0 ]
    then
        _format "$(logging.level.success)" "$1"
    fi
}

function logging.message {
    _format "${CRUCIBLE_LOGGING_LEVEL:-INFO}" "$1"
}

function logging.log {
    logging.message "$1"
}

function logging.set_level {
    if [ "${CRUCIBLE_LOGGING_LEVEL:-xxx__xxx}" == "xxx__xxx" ]
    then
        CRUCIBLE_LOGGING_LEVEL="$1"
    else
        if [ "$#" -gt 1 ]
        then
            if [ "$2" == "true" ]
            then
                CRUCIBLE_LOGGING_LEVEL="$1"
            fi
        fi
    fi
    
}

function logging.set_level_override {
    logging.set_level "$1" true
}