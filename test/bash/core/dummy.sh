#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
cd "$(dirname "$0")"
setup

cat .mould
source .mould

require core/dummy

declare -a tests

tests=("dummy.noop")

function dummy.noop {
    intro "Checking if noop exists"
    noop || fail "Noop does not exist"
    success
}

for test in "${tests[@]}"
do
    "$test"
done

teardown