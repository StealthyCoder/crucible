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
            _echo "$(cyan)[ INFO ] $2 $(reset)"
            ;;
        DEBUG)
            _echo "$(blue)[ DEBUG ] $2 $(reset)"
            ;;
        WARNING)
            _echo "$(yellow)[ WARNING ] $2 $(reset)"
            ;;
        ERROR)
            _echo "$(red)[ ERROR ] $2 $(reset)"
            ;;
        *)
            _echo "$(cyan)[ INFO ] $2 $(reset)"
            ;;
    esac
}

function cyan {
    _echo "$CYAN"
}

function yellow {
    _echo "$YELLOW"
}

function green {
    _echo "$GREEN"
}

function red {
    _echo "$RED"
}

function blue {
    _echo "$RED"
}

function reset {
    _echo "$RESET"
}

