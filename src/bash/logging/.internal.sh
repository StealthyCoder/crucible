#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.2.1
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1578009741
### CRUCIBLE META DATA ###

require logging/.constants

function _echo {
    echo -e "$1"
}

function _format {
    case $1 in
        INFO)
            _echo "$(__cyan)[ $1 ] $2 $(__reset)"
            ;;
        DEBUG)
            _echo "$(__blue)[ $1 ] $2 $(__reset)"
            ;;
        WARNING)
            _echo "$(__yellow)[ $1 ] $2 $(__reset)"
            ;;
        ERROR)
            _echo "$(__red)[ $1 ] $2 $(__reset)"
            ;;
        SUCCESS)
            _echo "$(__green)[ $1 ] $2 $(__reset)"
            ;;
        *)
            _echo "$(__cyan)[ $1 ] $2 $(__reset)"
            ;;
    esac
}

function __cyan {
    _echo "$(logging.color.cyan)"
}

function __yellow {
    _echo "$(logging.color.yellow)"
}

function __green {
    _echo "$(logging.color.green)"
}

function __red {
    _echo "$(logging.color.red)"
}

function __blue {
    _echo "$(logging.color.blue)"
}

function __reset {
    _echo "$(logging.color.reset)"
}

function __check_log_level {
    local set_log_level level_to_check
    set_log_level="$(__log_level_enum "${CRUCIBLE_LOGGING_LEVEL:-INFO}")"
    level_to_check="$(__log_level_enum "$1")"
    echo "$(( level_to_check <= set_log_level ))"
}