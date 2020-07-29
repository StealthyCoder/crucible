#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/maps/maps -p
cd tmp/maps/maps || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require maps/maps

declare -a tests

tests=("maps.maps.transform_into_map")
tests+=("maps.maps.put" "maps.maps.push")
tests+=("maps.maps.put_all")
tests+=("maps.maps.merge")
tests+=("maps.maps.get" "maps.maps.remove")
tests+=("maps.maps.values")
tests+=("maps.maps.keys")
tests+=("maps.maps.entries")
tests+=("maps.maps.clear")
# tests+=("arrays.arrays.map")
# tests+=("arrays.arrays.foreach")

function maps.maps.transform_into_map {
    intro "maps.maps.transform_into_map"
    maps.transform_into_map a
    
    __verify_if_arg_is_map a
    
    test $? -eq 0 || fail "Argument was not turned into map"
    
    success
}

function maps.maps.put {
    intro "maps.maps.put"
    maps.transform_into_map a
    
    maps.put a k v
    
    test $? -eq 0 || fail "Could not add to map"
    # shellcheck disable=SC2154
    test "${a[@]}" = "v" || fail "Map does not contain value"
    test "${!a[@]}" = "k" || fail "Map does not contain key"
    test "${a[k]}" = "v" || fail "Map does not contain key value combo"
    
    success
}

function maps.maps.push {
    intro "maps.maps.push"
    maps.transform_into_map a
    
    maps.push a k v
    
    test $? -eq 0 || fail "Could not add to map"
    # shellcheck disable=SC2154
    test "${a[@]}" = "v" || fail "Map does not contain value"
    test "${!a[@]}" = "k" || fail "Map does not contain key"
    test "${a[k]}" = "v" || fail "Map does not contain key value combo"
    
    success
}

function maps.maps.put_all {
    intro "maps.maps.put_all"
    maps.transform_into_map a
    
    maps.put_all a k v a 1
    
    test $? -eq 0 || fail "Could not add to map"
    __verify_nr_args "${#a[@]}" 2 maps.maps.put_all
    test $? -eq 0 || fail "Map does not contain all key value pairs"    
    test "${a[k]}" = "v" || fail "Map does not contain k,v"
    test "${a[a]}" = "1" || fail "Map does not contain a,1"

    success
}

function maps.maps.merge {
    intro "maps.maps.merge"
    maps.transform_into_map a
    maps.transform_into_map b
    
    maps.put_all a k v a 1
    maps.put b c 2

    maps.merge a b
    
    test $? -eq 0 || fail "Could not add to map"
    __verify_nr_args "${#a[@]}" 3 maps.maps.put_all
    test $? -eq 0 || fail "Map does not contain all key value pairs"
    test "${a[k]}" = "v" || fail "Map does not contain value k.v"
    test "${a[a]}" = 1 || fail "Map does not contain value a,1"
    test "${a[c]}" = 2 || fail "Map does not contain value c,2"

    success
}

function maps.maps.get {
    intro "maps.maps.get"
    local b
    maps.transform_into_map a
    
    maps.put a c 2
    b="$(maps.get a c)"

    test $? -eq 0 || fail "Could not get from map"
    
    test "$b" = 2 || fail "Did not get correct element"

    success
}

function maps.maps.remove {
    intro "maps.maps.remove"
    local b
    maps.transform_into_map a
    
    maps.put_all a k v a 1
    maps.remove a k

    test $? -eq 0 || fail "Could not get from array"
    
    test ! "${a[k]}" || fail "Failed to remove element"

    maps.remove a a

    test $? -eq 0 || fail "Could not get from array"
    
    test ! "${a[a]}" || fail "Failed to remove element"
    
    maps.remove a a 

    test $? -eq 0 || fail "Error thrown"

    __verify_nr_args "${#a[@]}" 0 maps.maps.remove
    test $? -eq 0 || fail "Map not cleared"

    success
}

function maps.maps.values {
    intro "maps.maps.values"
    local b
    maps.transform_into_map a
    
    maps.put_all a k v a 1
    b="$(maps.values a)"

    test $? -eq 0 || fail "Could not get from array"
    
    test "$b" = "v 1" || fail "Did not get correct element"

    success
}

function maps.maps.keys {
    intro "maps.maps.keys"
    local b
    maps.transform_into_map a
    
    maps.put_all a k v a 1
    b="$(maps.keys a)"

    test $? -eq 0 || fail "Could not get from array"
    
    test "$b" = "k a" || fail "Did not get correct element"

    success
}

function maps.maps.entries {
    intro "maps.maps.entries"
    local b
    
    maps.transform_into_map a
    
    maps.put_all a k v a 1
    b="$(maps.entries a)"
    
    test $? -eq 0 || fail "Could not get from array"
    
    b="$(echo "$b" | tr -d "[:cntrl:]")"
    echo "$b"
    test "$b" = "k,va,1" || fail "Did not get correct element"

    success
}

function maps.maps.clear {
    intro "maps.maps.clear"
        
    maps.transform_into_map a
    
    maps.put_all a k v a 1
        
    test $? -eq 0 || fail "Could not get from map"
    
    maps.clear a
    __verify_nr_args "${#a[@]}" 0 maps.maps.clear
    test $? -eq 0 || fail "Map not cleared"

    success
}

# function arrays.arrays.map {
#     intro "arrays.arrays.map"
    
#     local b
#     arrays.transform_into_array "a"

#     arrays.add_all a 1 2 3 4
    
#     b="$(arrays.values a)"

#     test $? -eq 0 || fail "Could not get from array"
    
#     test "$b" = "1 2 3 4" || fail "Array is not filled correctly"

#     function multiply_by_2 {
#         local result
#         result="$(($1 * 2))"
#         echo "$result"
#     }

#     arrays.map a multiply_by_2

#     b="$(arrays.values a)"

#     test $? -eq 0 || fail "Could not get from array"
    
#     test "$b" = "2 4 6 8" || fail "Array is not filled correctly"

#     arrays.clear a

#     success
# }

# function arrays.arrays.foreach {
#     intro "arrays.arrays.foreach"
    
#     local b counter
#     arrays.transform_into_array "a"

#     arrays.add_all a 1 2 3 4
    
#     b="$(arrays.values a)"

#     test $? -eq 0 || fail "Could not get from array"
    
#     test "$b" = "1 2 3 4" || fail "Array is not filled correctly, $b"

#     function simple_msg {
#         echo "simple,$1"
#     }

#     b=$(arrays.foreach a simple_msg)
#     test $? -eq 0 || fail "Could not get from array"
#     counter=1
#     for msg in $b
#     do
#         test "$msg" = "simple,$counter" || fail "Array is not filled correctly, $msg"
#         counter="$((counter + 1))"
#     done

#     success
# }

echo "Testing maps/maps"

for test in "${tests[@]}"
do
    "$test"
done

teardown