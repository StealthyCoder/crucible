#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/strings/strings -p
cd tmp/strings/strings || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require strings/strings

declare -a tests

tests=("strings.strings.case")
tests+=("strings.strings.replace_char_with" "strings.strings.search_and_replace")
tests+=("strings.strings.split_by_char")
tests+=("strings.strings.contains_string_sensitive")
tests+=("strings.strings.contains_string_ignore_case")
tests+=("strings.strings.substring" "strings.strings.slice")
tests+=("strings.strings.length")
tests+=("strings.strings.lindex" "strings.strings.rindex")
tests+=("strings.strings.is_empty")
tests+=("strings.strings.concat")
tests+=("strings.strings.equals" "strings.strings.equals_ignore_case")
tests+=("strings.strings.join")
tests+=("strings.strings.starts_with" "strings.strings.ends_with")
tests+=("strings.strings.starts_with_ignore_case")
tests+=("strings.strings.ends_with_ignore_case")

function strings.strings.case {
    intro "strings.strings.to_lowercase, to_uppercase and capitalize"
    assert_equals "hello world" "$(strings.to_lowercase "Hello WORLD")" "to_lowercase"
    assert_equals "HELLO WORLD" "$(strings.to_uppercase "Hello world")" "to_uppercase"
    assert_equals "Hello world" "$(strings.capitalize "hello world")" "capitalize"
    success
}

function strings.strings.replace_char_with {
    intro "strings.strings.replace_char_with"
    assert_equals "a_b_c" "$(strings.replace_char_with "a-b-c" "-" "_")" "replace all occurrences"
    assert_equals "abc" "$(strings.replace_char_with "a-b-c" "-" "")" "replace with nothing"
    assert_equals "abc" "$(strings.replace_char_with "abc" "-" "_")" "nothing to replace"
    success
}

function strings.strings.search_and_replace {
    intro "strings.strings.search_and_replace"
    assert_equals "a_b_c" "$(strings.search_and_replace "a-b-c" "-" "_")" "search and replace"
    success
}

function strings.strings.split_by_char {
    intro "strings.strings.split_by_char"
    assert_equals "a b c" "$(strings.split_by_char "a,b,c" ",")" "split on comma"
    assert_equals "abc" "$(strings.split_by_char "abc" ",")" "nothing to split"
    success
}

function strings.strings.contains_string_sensitive {
    intro "strings.strings.contains_string_sensitive"
    assert_true "should contain" strings.contains_string_sensitive "hello world" "lo wo"
    assert_false "should be case sensitive" strings.contains_string_sensitive "Hello" "hello"
    assert_false "should not contain" strings.contains_string_sensitive "hello" "xyz"
    success
}

function strings.strings.contains_string_ignore_case {
    intro "strings.strings.contains_string_ignore_case"
    assert_true "should contain ignoring case" strings.contains_string_ignore_case "Hello World" "WORLD"
    assert_true "should contain exact" strings.contains_string_ignore_case "hello" "hello"
    assert_false "should not contain" strings.contains_string_ignore_case "Hello World" "xyz"
    success
}

function strings.strings.substring {
    intro "strings.strings.substring"
    assert_equals "ell" "$(strings.substring "hello" 1 3)" "substring"
    success
}

function strings.strings.slice {
    intro "strings.strings.slice"
    assert_equals "ell" "$(strings.slice "hello" 1 3)" "slice"
    success
}

function strings.strings.length {
    intro "strings.strings.length"
    assert_equals "5" "$(strings.length "hello")" "length"
    assert_equals "0" "$(strings.length "")" "empty length"
    success
}

function strings.strings.lindex {
    intro "strings.strings.lindex"
    assert_equals "4" "$(strings.lindex "hello world" "o")" "first index of o"
    assert_equals "0" "$(strings.lindex "hello" "h")" "first index at start"
    success
}

function strings.strings.rindex {
    intro "strings.strings.rindex"
    assert_equals "7" "$(strings.rindex "hello world" "o")" "last index of o"
    success
}

function strings.strings.is_empty {
    intro "strings.strings.is_empty"
    assert_true "empty string" strings.is_empty ""
    assert_true "whitespace only" strings.is_empty "   "
    assert_false "has content" strings.is_empty "a"
    success
}

function strings.strings.concat {
    intro "strings.strings.concat"
    assert_equals "foobar" "$(strings.concat "foo" "bar")" "concat"
    success
}

function strings.strings.equals {
    intro "strings.strings.equals"
    assert_true "equal" strings.equals "abc" "abc"
    assert_false "different" strings.equals "abc" "abd"
    assert_false "case differs" strings.equals "abc" "ABC"
    assert_false "prefix only" strings.equals "abc" "ab"
    success
}

function strings.strings.equals_ignore_case {
    intro "strings.strings.equals_ignore_case"
    assert_true "equal ignoring case" strings.equals_ignore_case "abc" "ABC"
    assert_false "different" strings.equals_ignore_case "abc" "abd"
    success
}

function strings.strings.join {
    intro "strings.strings.join"
    arrays.transform_into_array parts
    arrays.add parts a
    arrays.add parts b
    arrays.add parts c
    assert_equals "a-b-c" "$(strings.join parts -)" "join with dash"
    assert_equals "a, b, c" "$(strings.join parts ', ')" "join with multi character delimiter"
    success
}

function strings.strings.starts_with {
    intro "strings.strings.starts_with"
    assert_true "starts with" strings.starts_with "hello" "he"
    assert_false "does not start with" strings.starts_with "hello" "lo"
    assert_false "case differs" strings.starts_with "hello" "HE"
    success
}

function strings.strings.ends_with {
    intro "strings.strings.ends_with"
    assert_true "ends with" strings.ends_with "hello" "lo"
    assert_false "does not end with" strings.ends_with "hello" "he"
    assert_false "case differs" strings.ends_with "hello" "LO"
    success
}

function strings.strings.starts_with_ignore_case {
    intro "strings.strings.starts_with_ignore_case"
    assert_true "starts with ignoring case" strings.starts_with_ignore_case "hello" "HE"
    assert_false "does not start with" strings.starts_with_ignore_case "hello" "LO"
    success
}

function strings.strings.ends_with_ignore_case {
    intro "strings.strings.ends_with_ignore_case"
    assert_true "ends with ignoring case" strings.ends_with_ignore_case "hello" "LO"
    assert_false "does not end with" strings.ends_with_ignore_case "hello" "HE"
    success
}

echo "Testing strings/strings"

for test in "${tests[@]}"; do
    "$test"
done

teardown
