#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require logging/constants

function _echo {
    echo -e "$1"
}

function _format {
    case $1 in
        INFO)
            _echo "$(__cyan)[ INFO ] $2 $(__reset)"
            ;;
        DEBUG)
            _echo "$(__blue)[ DEBUG ] $2 $(__reset)"
            ;;
        WARNING)
            _echo "$(__yellow)[ WARNING ] $2 $(__reset)"
            ;;
        ERROR)
            _echo "$(__red)[ ERROR ] $2 $(__reset)"
            ;;
        SUCCESS)
            _echo "$(__green)[ SUCCESS ] $2 $(__reset)"
            ;;
        *)
            _echo "$(__cyan)[ INFO ] $2 $(__reset)"
            ;;
    esac
}

function __cyan {
    _echo "$CYAN"
}

function __yellow {
    _echo "$YELLOW"
}

function __green {
    _echo "$GREEN"
}

function __red {
    _echo "$RED"
}

function __blue {
    _echo "$RED"
}

function __reset {
    _echo "$RESET"
}

