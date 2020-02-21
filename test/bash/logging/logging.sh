#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/logging/logging -p
cd tmp/logging/logging || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require logging/logging

declare -a tests

tests=("logging.logging.set_level")
tests+=("logging.logging.set_level_override")
tests+=("logging.logging.info")
tests+=("logging.logging.debug")
tests+=("logging.logging.error")
tests+=("logging.logging.warning")
tests+=("logging.logging.success")
tests+=("logging.logging.message" "logging.logging.log")

function logging.logging.set_level {
    intro "logging.logging.set_level"
    logging.set_level "$(logging.level.debug)"
    test "$CRUCIBLE_LOGGING_LEVEL" = "DEBUG" || fail "Level was not correctly set"
    
    logging.set_level "$(logging.level.error)"
    test "$CRUCIBLE_LOGGING_LEVEL" = "DEBUG" || fail "Level was not correctly set"

    logging.set_level "$(logging.level.error)" true
    test "$CRUCIBLE_LOGGING_LEVEL" = "ERROR" || fail "Level was not correctly set"

    unset CRUCIBLE_LOGGING_LEVEL
    success
}

function logging.logging.set_level_override {
    intro "logging.logging.set_level_override"
    logging.set_level "$(logging.level.debug)"
    test "$CRUCIBLE_LOGGING_LEVEL" = "DEBUG" || fail "Level was not correctly set"
    
    logging.set_level_override "$(logging.level.error)"
    test "$CRUCIBLE_LOGGING_LEVEL" = "ERROR" || fail "Level was not correctly set"

    unset CRUCIBLE_LOGGING_LEVEL
    success
}

function logging.logging.info {
    intro "logging.logging.info"
    local msg
    msg="$(logging.info Cookie | tr -d -C '[:print:]')"
    pattern="\\[38;5;86m\\[ INFO \\] .* Cookie \\[0m"
    
    if [[ "$msg" =~ $pattern ]]
    then
        success
    else
        fail "Message was wrong format $msg"
    fi
    
}

function logging.logging.debug {
    intro "logging.logging.debug"
    local msg
    msg="$(logging.debug Cookie | tr -d -C '[:print:]')"
    test -z "$msg" || fail "Message was displayed yet level was lower"

    logging.set_level "$(logging.level.debug)"
    msg="$(logging.debug Cookie | tr -d -C '[:print:]')"
    pattern="\\[34m\\[ DEBUG \\] .* Cookie \\[0m"
    
    if [[ "$msg" =~ $pattern ]]
    then
        success
    else
        fail "Message was wrong format $msg"
    fi
    
    unset CRUCIBLE_LOGGING_LEVEL
}

function logging.logging.error {
    intro "logging.logging.error"
    local msg
    msg="$(logging.error Cookie | tr -d -C '[:print:]')"
    pattern="\\[38;5;196m\\[ ERROR \\] .* Cookie \\[0m"
    
    if [[ "$msg" =~ $pattern ]]
    then
        success
    else
        fail "Message was wrong format $msg"
    fi
}

function logging.logging.warning {
    intro "logging.logging.warning"
    local msg
    msg="$(logging.warning Cookie | tr -d -C '[:print:]')"
    test -z "$msg" || fail "Message was displayed yet level was lower"

    logging.set_level "$(logging.level.warning)"
    msg="$(logging.warning Cookie | tr -d -C '[:print:]')"
    pattern="\\[93m\\[ WARNING \\] .* Cookie \\[0m"
    
    if [[ "$msg" =~ $pattern ]]
    then
        success
    else
        fail "Message was wrong format $msg"
    fi
    
    unset CRUCIBLE_LOGGING_LEVEL
}

function logging.logging.success {
    intro "logging.logging.success"
    local msg
    msg="$(logging.success Cookie | tr -d -C '[:print:]')"
    pattern="\\[38;5;82m\\[ SUCCESS \\] .* Cookie \\[0m"
    
    if [[ "$msg" =~ $pattern ]]
    then
        success
    else
        fail "Message was wrong format $msg"
    fi
    
}

function logging.logging.message {
    intro "logging.logging.message"
    local msg
    msg="$(logging.message Cookie | tr -d -C '[:print:]')"
    pattern="\\[38;5;86m\\[ INFO \\] .* Cookie \\[0m"
    
    if [[ "$msg" =~ $pattern ]]
    then
        success
    else
        fail "Message was wrong format $msg"
    fi
    
}

function logging.logging.log {
    intro "logging.logging.log"
    local msg
    msg="$(logging.log Cookie | tr -d -C '[:print:]')"
    pattern="\\[38;5;86m\\[ INFO \\] .* Cookie \\[0m"
    
    if [[ "$msg" =~ $pattern ]]
    then
        success
    else
        fail "Message was wrong format $msg"
    fi
}

echo "Testing logging/logging"

for test in "${tests[@]}"
do
    "$test"
done

teardown