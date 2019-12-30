#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/arrays/arrays -p
cd tmp/arrays/arrays || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require arrays/arrays

declare -a tests

tests=("arrays.arrays.transform_into_array")
tests+=("arrays.arrays.add" "arrays.arrays.push")
tests+=("arrays.arrays.add_all")
tests+=("arrays.arrays.concat")
tests+=("arrays.arrays.get" "arrays.arrays.pop")

function arrays.arrays.transform_into_array {
    intro "arrays.arrays.transform_into_array"
    arrays.transform_into_array a
    
    __verify_if_arg_is_array a
    
    test $? -eq 0 || fail "Argument was not turned into array"
    
    success
}

function arrays.arrays.add {
    intro "arrays.arrays.add"
    arrays.transform_into_array a
    
    arrays.add a 1
    
    test $? -eq 0 || fail "Could not add to array"

    test "${a[@]}" = "1" || fail "Array does not contain element"
    
    success
}

function arrays.arrays.push {
    intro "arrays.arrays.push"
    arrays.transform_into_array a
    
    arrays.push a 1
    
    test $? -eq 0 || fail "Could not add to array"

    test "${a[@]}" = "1" || fail "Array does not contain element"
    
    success
}

function arrays.arrays.add_all {
    intro "arrays.arrays.add_all"
    arrays.transform_into_array a
    
    arrays.add_all a 1 2 3 4 5
    
    test $? -eq 0 || fail "Could not add to array"
    
    test "${#a[@]}" = "5" || fail "Array does not contain all elements"

    success
}

function arrays.arrays.concat {
    intro "arrays.arrays.concat"
    arrays.transform_into_array a
    arrays.transform_into_array b
    
    arrays.add_all a 1 2 3 4 5
    arrays.add_all b 6 7 8 9

    arrays.concat a b
    
    test $? -eq 0 || fail "Could not concat arrays"
    
    test "${#a[@]}" = "9" || fail "Array does not contain all elements"

    success
}

function arrays.arrays.get {
    intro "arrays.arrays.get"
    local b
    arrays.transform_into_array a
    
    arrays.add_all a 1
    b="$(arrays.get a 0)"

    test $? -eq 0 || fail "Could get from array"
    
    test "$b" = 1 || fail "Did not get correct element"

    success
}

function arrays.arrays.pop {
    intro "arrays.arrays.pop"
    local b
    arrays.transform_into_array a
    
    arrays.add_all a 1 2
    echo ${a[@]}
    b="$(arrays.pop a)"
    echo ${a[@]}
    test $? -eq 0 || fail "Could get from array"
    
    test "$b" = 2 || fail "Did not get correct element, expected 2 got $b"

    b="$(arrays.pop a)"

    test $? -eq 0 || fail "Could get from array"
    
    test "$b" = 1 || fail "Did not get correct element, expected 1 got $b"
    
    b="$(arrays.pop a)"

    test $? -eq 0 || fail "Error thrown"

    success
}

for test in "${tests[@]}"
do
    "$test"
done

teardown