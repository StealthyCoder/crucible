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
    _echo "$BLUE"
}

function __reset {
    _echo "$RESET"
}

