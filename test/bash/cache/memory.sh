#!/usr/bin/env bash
# The caches are arrays that are named like the cache and made by declare -g
# shellcheck disable=SC1090,SC2154
source "$(dirname "$0")/../../.utils"
mkdir tmp/cache/memory -p
cd tmp/cache/memory || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require cache/memory

declare -a tests

tests=("cache.memory.test.put_and_get" "cache.memory.test.missing")
tests+=("cache.memory.test.overwrite" "cache.memory.test.remove_and_clear")
tests+=("cache.memory.test.expiry" "cache.memory.test.default_ttl" "cache.memory.test.ttl_command")
tests+=("cache.memory.test.size_keys_evict")
tests+=("cache.memory.test.awkward_keys_and_values")
tests+=("cache.memory.test.caches_are_separate")
tests+=("cache.memory.test.get_or_compute")
tests+=("cache.memory.test.stats")
tests+=("cache.memory.test.invalid_use")
tests+=("cache.memory.test.destroy")

# The clock is set by the tests, nobody sleeps
export CRUCIBLE_CACHE_NOW=1000

function cache.memory.test.put_and_get {
    intro "cache.memory.put and get"
    cache.memory.create colours
    cache.memory.put colours sky blue
    assert_equals "blue" "$(cache.memory.get colours sky)" "get"
    assert_true "has" cache.memory.has colours sky
    assert_equals "blue" "${colours[sky]}" "the cache is an associative array with its own name"
    success
}

function cache.memory.test.missing {
    intro "cache.memory.get of something that is not there"
    assert_false "missing key" quietly cache.memory.get colours grass
    assert_false "missing key has" cache.memory.has colours grass
    assert_equals "" "$(cache.memory.get colours grass)" "nothing is printed"
    success
}

function cache.memory.test.overwrite {
    intro "cache.memory.put overwrites"
    cache.memory.put colours sky grey
    assert_equals "grey" "$(cache.memory.get colours sky)" "overwritten"
    assert_equals "1" "$(cache.memory.size colours)" "still one entry"
    success
}

function cache.memory.test.remove_and_clear {
    intro "cache.memory.remove and clear"
    cache.memory.put colours grass green
    cache.memory.remove colours sky
    assert_false "removed" cache.memory.has colours sky
    assert_true "other entries stay" cache.memory.has colours grass
    cache.memory.clear colours
    assert_equals "0" "$(cache.memory.size colours)" "cleared"
    assert_true "removing what is not there is fine" cache.memory.remove colours nothing
    success
}

function cache.memory.test.expiry {
    intro "cache.memory.put with a ttl"
    CRUCIBLE_CACHE_NOW=1000
    cache.memory.put colours short value 10
    cache.memory.put colours forever value 0
    CRUCIBLE_CACHE_NOW=1009
    assert_true "still there one second before" cache.memory.has colours short
    CRUCIBLE_CACHE_NOW=1010
    assert_false "gone when the ttl has passed" cache.memory.has colours short
    assert_false "get of an expired entry" quietly cache.memory.get colours short
    assert_true "an entry without ttl never expires" cache.memory.has colours forever
    CRUCIBLE_CACHE_NOW=999999999
    assert_true "not even after a very long time" cache.memory.has colours forever
    assert_equals "" "${colours[short]-}" "an expired entry is also removed from the array"
    CRUCIBLE_CACHE_NOW=1000
    cache.memory.clear colours
    success
}

function cache.memory.test.default_ttl {
    intro "cache.memory.create with a default ttl"
    CRUCIBLE_CACHE_NOW=1000
    cache.memory.create sessions 60
    cache.memory.put sessions a 1
    cache.memory.put sessions b 2 5
    cache.memory.put sessions c 3 0
    CRUCIBLE_CACHE_NOW=1005
    assert_true "a lives on the default" cache.memory.has sessions a
    assert_false "b had its own ttl of 5" cache.memory.has sessions b
    CRUCIBLE_CACHE_NOW=1060
    assert_false "a is gone after the default ttl" cache.memory.has sessions a
    assert_true "c has no ttl although the default has one" cache.memory.has sessions c
    CRUCIBLE_CACHE_NOW=1000
    success
}

function cache.memory.test.ttl_command {
    intro "cache.memory.ttl"
    CRUCIBLE_CACHE_NOW=1000
    cache.memory.clear colours
    cache.memory.put colours short value 30
    cache.memory.put colours forever value
    CRUCIBLE_CACHE_NOW=1012
    assert_equals "18" "$(cache.memory.ttl colours short)" "seconds left"
    assert_equals "-1" "$(cache.memory.ttl colours forever)" "no expiry"
    assert_false "no such entry" quietly cache.memory.ttl colours nothing
    CRUCIBLE_CACHE_NOW=1000
    success
}

function cache.memory.test.size_keys_evict {
    intro "cache.memory.size, keys and evict_expired"
    CRUCIBLE_CACHE_NOW=1000
    cache.memory.clear colours
    cache.memory.put colours a 1 5
    cache.memory.put colours b 2 5
    cache.memory.put colours c 3
    assert_equals "3" "$(cache.memory.size colours)" "size"
    assert_equals "a b c" "$(cache.memory.keys colours | sort | tr '\n' ' ' | sed 's/ $//')" "keys"
    CRUCIBLE_CACHE_NOW=1006
    # Nothing has looked at a and b yet, they are still in the array
    assert_equals "3" "${#colours[@]}" "expired entries are only removed when seen"
    # Called directly: what a subshell removes is back in this shell
    cache.memory.evict_expired colours >evicted.txt
    assert_equals "2" "$(cat evicted.txt)" "evicted"
    rm evicted.txt
    assert_equals "1" "${#colours[@]}" "left after evicting"
    assert_equals "c" "$(cache.memory.keys colours)" "keys without the expired"
    CRUCIBLE_CACHE_NOW=1000
    success
}

function cache.memory.test.awkward_keys_and_values {
    intro "cache.memory with awkward keys and values"
    local key
    local -a keys
    keys=('with space' 'a]b' "it's" 'say "hi"' '$HOME' '*' '@' '[x]' 'back\slash' 'tab	tab' 'ünïcode' '-n' 'a|b' '1|2')
    cache.memory.create awkward
    for key in "${keys[@]}"; do
        cache.memory.put awkward "$key" "value of $key" 100
    done
    assert_equals "${#keys[@]}" "$(cache.memory.size awkward)" "all keys are separate entries"
    for key in "${keys[@]}"; do
        assert_equals "value of $key" "$(cache.memory.get awkward "$key")" "key [$key]"
    done
    cache.memory.remove awkward '*'
    assert_false "removing * removes only *" cache.memory.has awkward '*'
    assert_equals "$((${#keys[@]} - 1))" "$(cache.memory.size awkward)" "nothing else was removed"
    cache.memory.remove awkward 'a]b'
    assert_false "removing a]b" cache.memory.has awkward 'a]b'
    assert_equals "$((${#keys[@]} - 2))" "$(cache.memory.size awkward)" "nothing else was removed by a]b"
    cache.memory.put awkward multi "line one
line two"
    assert_equals "line one
line two" "$(cache.memory.get awkward multi)" "multi line value"
    cache.memory.put awkward spaces "  padded  "
    assert_equals "  padded  " "$(cache.memory.get awkward spaces)" "spaces around a value"
    cache.memory.put awkward empty ""
    assert_true "an empty value is a value" cache.memory.has awkward empty
    assert_equals "" "$(cache.memory.get awkward empty)" "empty value"
    success
}

function cache.memory.test.caches_are_separate {
    intro "caches do not share entries"
    cache.memory.create one
    cache.memory.create two
    cache.memory.put one k first
    cache.memory.put two k second 5
    assert_equals "first" "$(cache.memory.get one k)" "first cache"
    assert_equals "second" "$(cache.memory.get two k)" "second cache"
    CRUCIBLE_CACHE_NOW=1010
    assert_true "the expiry of two does not touch one" cache.memory.has one k
    assert_false "two expired" cache.memory.has two k
    CRUCIBLE_CACHE_NOW=1000
    success
}

function cache.memory.test.get_or_compute {
    intro "cache.memory.get_or_compute_into and get_or_compute"
    local result
    function compute_length {
        echo "x" >>computed.log
        echo "length:${#1}"
    }
    function compute_fails {
        return 3
    }
    function compute_lines {
        printf 'one\ntwo\n\n'
    }
    cache.memory.create computed
    cache.memory.get_or_compute_into result computed hello compute_length
    assert_equals "length:5" "$result" "computed"
    cache.memory.get_or_compute_into result computed hello compute_length
    assert_equals "length:5" "$result" "from the cache"
    assert_equals "1" "$(wc -l <computed.log | tr -d ' ')" "the function ran once"
    cache.memory.get_or_compute computed other compute_length >out.txt
    assert_equals "length:5" "$(cat out.txt)" "the printing form"
    cache.memory.get_or_compute computed other compute_length >out.txt
    assert_equals "2" "$(wc -l <computed.log | tr -d ' ')" "the printing form uses the cache too when called directly"
    cache.memory.get_or_compute_into result computed broken compute_fails
    assert_equals "3" "$?" "the failure is passed on"
    assert_false "nothing stored for a failure" cache.memory.has computed broken
    cache.memory.get_or_compute_into result computed ttl compute_length 5
    CRUCIBLE_CACHE_NOW=1006
    assert_false "ttl is honoured" cache.memory.has computed ttl
    CRUCIBLE_CACHE_NOW=1000
    cache.memory.get_or_compute_into result computed x not_a_function >/dev/null 2>&1
    test $? -ne 0 || fail "A function that does not exist should fail"
    cache.memory.get_or_compute_into result computed lines compute_lines
    assert_equals "one
two" "$result" "trailing line breaks are lost, the others are not"
    rm computed.log out.txt
    success
}

function cache.memory.test.stats {
    intro "cache.memory.test.stats"
    cache.memory.create counted
    cache.memory.put counted a 1
    cache.memory.get counted a >/dev/null
    cache.memory.get counted a >/dev/null
    cache.memory.get counted b >/dev/null
    assert_equals "hits=2 misses=1" "$(cache.memory.stats counted)" "stats"
    success
}

function cache.memory.test.invalid_use {
    intro "cache.memory with invalid input"
    assert_false "name with a dash" quietly cache.memory.create a-b
    assert_false "name starting with a digit" quietly cache.memory.create 1abc
    assert_false "reserved name" quietly cache.memory.create CRUCIBLE_THING
    assert_false "name of a variable that exists" quietly cache.memory.create PATH
    assert_equals "$PATH" "$PATH" "PATH is untouched"
    assert_false "unknown cache" quietly cache.memory.put nonexistent k v
    assert_false "ttl that is not a number" quietly cache.memory.put colours k v soon
    assert_false "empty key" quietly cache.memory.put colours "" v
    assert_false "default ttl that is not a number" quietly cache.memory.create other soon
    success
}

function cache.memory.test.destroy {
    intro "cache.memory.test.destroy"
    cache.memory.create doomed
    cache.memory.put doomed a 1 50
    cache.memory.destroy doomed
    assert_false "the cache is gone" quietly cache.memory.has doomed a
    declare -p doomed >/dev/null 2>&1 && fail "The array of the cache is still there"
    assert_true "the name can be used again" cache.memory.create doomed
    assert_equals "0" "$(cache.memory.size doomed)" "empty after creating again"
    success
}

echo "Testing cache/memory"

for test in "${tests[@]}"; do
    "$test"
done

teardown
