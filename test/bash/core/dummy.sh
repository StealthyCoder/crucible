#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/core/dummy -p
cd tmp/core/dummy || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require core/dummy

declare -a tests

tests=("dummy.noop")

function dummy.noop {
    intro "Checking if noop exists"
    noop || fail "Noop does not exist"
    success
}

echo "Testing core/dummy"

for test in "${tests[@]}"
do
    "$test"
done

teardown