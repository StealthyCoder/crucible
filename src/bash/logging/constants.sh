#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###


# shellcheck disable=SC1117
ESCAPE_CHAR="\033["
# shellcheck disable=SC2034
CYAN="${ESCAPE_CHAR}96m"
# shellcheck disable=SC2034
BLUE="${ESCAPE_CHAR}34m"
# shellcheck disable=SC2034
GREEN="${ESCAPE_CHAR}32m"
# shellcheck disable=SC2034
YELLOW="${ESCAPE_CHAR}93m"
# shellcheck disable=SC2034
RED="${ESCAPE_CHAR}31m"
# shellcheck disable=SC2034
RESET="${ESCAPE_CHAR}0m"

function logging.level.info {
    echo "INFO"
}

function logging.level.debug {
    echo "DEBUG"
}

function logging.level.warning {
    echo "WARNING"
}

function logging.level.error {
    echo "ERROR"
}

function logging.level.success {
    echo "SUCCESS"
}