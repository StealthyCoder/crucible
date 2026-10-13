#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/pipes/pipes -p
cd tmp/pipes/pipes || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require pipes/pipes

declare -a tests

tests=("pipes.pipes.pipe_to" "pipes.pipes.pipe_text_to")

function pipes.pipes.pipe_to {
    intro "pipes.pipes.pipe_to"
    assert_equals "HELLO" "$(pipes.pipe_to "echo hello" "tr a-z A-Z")" "output of command was not piped"
    success
}

function pipes.pipes.pipe_text_to {
    intro "pipes.pipes.pipe_text_to"
    assert_equals "HELLO" "$(pipes.pipe_text_to "hello" "tr a-z A-Z")" "text was not piped"
    assert_equals "2" "$(pipes.pipe_text_to "a
b" "wc -l")" "multi line text was not piped"
    success
}

echo "Testing pipes/pipes"

for test in "${tests[@]}"; do
    "$test"
done

teardown
