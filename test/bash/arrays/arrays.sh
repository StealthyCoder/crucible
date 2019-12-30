#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/arrays/arrays -p
cd tmp/arrays/arrays || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould
cat .crucible

require arrays/arrays

declare -a tests

tests=("arrays.arrays.transform_into_array")

function arrays.arrays.transform_into_array {
    intro "arrays.arrays.transform_into_array"
    arrays.transform_into_array a
    __verify_if_arg_is_array "$a"
    declare -p a
    test $? -eq 0 || fail "Argument was not turned into array"
    success
}

for test in "${tests[@]}"
do
    "$test"
done

teardown