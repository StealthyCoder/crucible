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
    _format "$(logging.level.debug)" "$1"
}

function logging.warning {
    _format "$(logging.level.warning)" "$1"
}

function logging.error {
    _format "$(logging.level.error)" "$1"
}

function logging.success {
    _format "$(logging.level.success)" "$1"
}

function logging.message {
    _format "${CRUCIBLE_LOGGING_LEVEL:-INFO}" "$1"
}