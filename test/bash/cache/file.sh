#!/usr/bin/env bash
# The caches are arrays that are named like the cache and made by declare -g
# shellcheck disable=SC1090,SC2154
source "$(dirname "$0")/../../.utils"
mkdir tmp/cache/file -p
cd tmp/cache/file || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require cache/file

declare -a tests

tests=("cache.file.test.persistence" "cache.file.test.file_format")
tests+=("cache.file.test.shared_between_caches")
tests+=("cache.file.test.expiry")
tests+=("cache.file.test.remove_and_clear")
tests+=("cache.file.test.awkward_keys_and_values")
tests+=("cache.file.test.get_or_compute")
tests+=("cache.file.test.file_is_data_not_code")
tests+=("cache.file.test.damaged_file")
tests+=("cache.file.test.invalid_use")

# The clock is set by the tests, nobody sleeps
export CRUCIBLE_CACHE_NOW=1000

function cache.file.test.persistence {
    intro "cache.file survives the script that wrote it"
    cache.file.create store store.cache
    cache.file.put store answer 42
    # Another script is another process: it knows nothing but the file
    (
        source .mould
        require cache/file
        cache.file.create reader store.cache
        test "$(cache.file.get reader answer)" = "42"
    ) || fail "A fresh process did not find the entry"
    assert_equals "42" "$(cache.file.get store answer)" "get"
    assert_true "has" cache.file.has store answer
    assert_equals "1" "$(cache.file.size store)" "size"
    assert_equals "answer" "$(cache.file.keys store)" "keys"
    success
}

function cache.file.test.file_format {
    intro "cache.file writes a plain file that only its owner can read"
    assert_equals "# crucible cache 1" "$(head -n 1 store.cache)" "header"
    assert_equals "0|answer|42" "$(sed -n 2p store.cache)" "entry"
    assert_equals "600" "$(stat -c '%a' store.cache)" "permissions of a new file"
    success
}

function cache.file.test.shared_between_caches {
    intro "cache.file: two caches on one file see each other"
    cache.file.create writer shared.cache
    cache.file.create reader shared.cache
    cache.file.put writer colour blue
    assert_equals "blue" "$(cache.file.get reader colour)" "written by one, read by the other"
    cache.file.put reader colour red
    assert_equals "red" "$(cache.file.get writer colour)" "and back"
    success
}

function cache.file.test.expiry {
    intro "cache.file keeps the expiry"
    CRUCIBLE_CACHE_NOW=1000
    cache.file.create timed timed.cache 30
    cache.file.put timed short v 10
    cache.file.put timed default v
    cache.file.put timed forever v 0
    assert_equals "0|forever|v" "$(grep '|forever|' timed.cache)" "no expiry is 0"
    assert_equals "1010|short|v" "$(grep '|short|' timed.cache)" "expiry is an absolute time"
    assert_equals "1030|default|v" "$(grep '|default|' timed.cache)" "default ttl is used"
    CRUCIBLE_CACHE_NOW=1010
    assert_false "expired entry is not returned" cache.file.has timed short
    assert_true "the others are" cache.file.has timed default
    cache.file.create latecomer timed.cache
    assert_equals "2" "$(cache.file.size latecomer)" "a new cache does not load expired entries"
    cache.file.put timed other v
    grep -q '|short|' timed.cache && fail "An expired entry was written back to the file"
    assert_equals "20" "$(cache.file.ttl timed default)" "ttl of an entry in the file"
    CRUCIBLE_CACHE_NOW=1000
    success
}

function cache.file.test.remove_and_clear {
    intro "cache.file.remove and clear are written to the file"
    cache.file.create editable editable.cache
    cache.file.put editable a 1
    cache.file.put editable b 2
    cache.file.remove editable a
    grep -q '|a|' editable.cache && fail "Removed entry is still in the file"
    grep -q '|b|' editable.cache || fail "Other entry is gone from the file"
    cache.file.clear editable
    assert_equals "0" "$(cache.file.size editable)" "cleared"
    assert_equals "1" "$(wc -l <editable.cache | tr -d ' ')" "only the header is left in the file"
    success
}

function cache.file.test.awkward_keys_and_values {
    intro "cache.file round trips awkward keys and values"
    local key value
    local -a keys values
    keys=('plain' 'with space' 'a|b' '100%' '%7C' '%0A' 'new
line' 'cr
' 'tab	tab' '$(touch pwned)' '`touch pwned`' 'ünïcode ✓' '*' 'a]b')
    values=('' ' padded ' 'p|i|p|e' '50%' '%25' '%0D' 'two
lines
' '$(touch pwned)' '\n' '\\' "quote's" '"double"' 'end')
    cache.file.create awkward awkward.cache
    local i
    for i in "${!keys[@]}"; do
        cache.file.put awkward "${keys[$i]}" "${values[$i]}"
    done
    # Read it back through a cache that only knows the file
    cache.file.create audit awkward.cache
    for i in "${!keys[@]}"; do
        key="${keys[$i]}"
        value="${values[$i]}"
        cache.memory.has audit "$key" || fail "Key [$key] was lost"
        # Not through get: $(...) would strip a line break at the end of a value
        assert_equals "$value" "${audit["$key"]}" "value of key [$key]"
    done
    assert_equals "${#keys[@]}" "$(cache.file.size audit)" "number of entries"
    test ! -e pwned || fail "Something in the cache was executed"
    success
}

function cache.file.test.get_or_compute {
    intro "cache.file.get_or_compute_into stores what it computes"
    local result
    function compute_it {
        echo "x" >>runs.log
        echo "computed:$1"
    }
    cache.file.create lazy lazy.cache
    cache.file.get_or_compute_into result lazy k compute_it
    assert_equals "computed:k" "$result" "computed"
    cache.file.create other lazy.cache
    cache.file.get_or_compute_into result other k compute_it
    assert_equals "computed:k" "$result" "taken from the file by another cache"
    assert_equals "1" "$(wc -l <runs.log | tr -d ' ')" "the function ran once"
    cache.file.get_or_compute lazy k compute_it >out.txt
    assert_equals "computed:k" "$(cat out.txt)" "the printing form"
    rm runs.log out.txt
    success
}

function cache.file.test.file_is_data_not_code {
    intro "a file cache that was tampered with does not run code"
    printf '# crucible cache 1\n0|key|$(touch pwned)\n0|$(touch pwned)|`touch pwned`\n' >evil.cache
    cache.file.create evil evil.cache
    assert_equals '$(touch pwned)' "$(cache.file.get evil key)" "the payload is just a value"
    test ! -e pwned || fail "The file was executed"
    success
}

function cache.file.test.damaged_file {
    intro "a damaged cache file is survived"
    printf 'garbage\n\n|||\nnot|enough\n5|\nabc|k|v\n0|good|value\n' >damaged.cache
    cache.file.create damaged damaged.cache
    assert_equals "value" "$(cache.file.get damaged good)" "the good entry"
    assert_equals "1" "$(cache.file.size damaged)" "nothing else was taken"
    cache.file.create missing does-not-exist.cache
    assert_equals "0" "$(cache.file.size missing)" "a file that is not there is an empty cache"
    printf '0|last|no newline at the end' >nonewline.cache
    cache.file.create nonewline nonewline.cache
    assert_equals "no newline at the end" "$(cache.file.get nonewline last)" "last line without line break"
    success
}

function cache.file.test.invalid_use {
    intro "cache.file with invalid input"
    cache.memory.create onlymemory
    assert_false "a memory cache is no file cache" quietly cache.file.put onlymemory k v
    assert_false "no file" quietly cache.file.create nofile ""
    assert_false "unknown cache" quietly cache.file.get unknown k
    assert_false "wrong number of arguments" quietly cache.file.create justname
    success
}

echo "Testing cache/file"

for test in "${tests[@]}"; do
    "$test"
done

teardown
