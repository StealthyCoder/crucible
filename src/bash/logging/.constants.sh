#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.2.7
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1647267741
### CRUCIBLE META DATA ###

function logging.color.escape_char {
    echo -e "\\033["
}

function logging.color.cyan {
    echo -e "$(logging.color.escape_char)38;5;86m"
}

function logging.color.blue {
    echo -e "$(logging.color.escape_char)34m"
}

function logging.color.green {
    echo -e "$(logging.color.escape_char)38;5;82m"
}

function logging.color.yellow {
    echo -e "$(logging.color.escape_char)93m"
}

function logging.color.red {
    echo -e "$(logging.color.escape_char)38;5;196m"
}

function logging.color.reset {
    echo -e "$(logging.color.escape_char)0m"
}

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

function __log_level_enum {
    case $1 in
        INFO|SUCCESS|ERROR)
            echo 1
            ;;
        DEBUG)
            echo 3
            ;;
        WARNING)
            echo 2
            ;;
        *)
            echo 1
            ;;
    esac
}