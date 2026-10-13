#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/os/os -p
cd tmp/os/os || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require os/os

declare -a tests

tests=("os.os.get_architecture")

function os.os.get_architecture {
    intro "os.os.get_architecture"
    assert_equals "$(uname -m)" "$(os.get_architecture)" "get_architecture"
    success
}

echo "Testing os/os"

for test in "${tests[@]}"; do
    "$test"
done

teardown
