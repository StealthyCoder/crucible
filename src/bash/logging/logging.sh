#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require logging/internal

function logging.info {
    _format "$(logging.level.info)" "$1"
}

function logging.debug {
    _format "$DEBUG" "$1"
}

function logging.warning {
    _format "$WARNING" "$1"
}

function logging.error {
    _format "$ERROR" "$1"
}

function logging.success {
    _format "$SUCCESS" "$1"
}

function logging.message {
    _format "$INFO" "$1"
}