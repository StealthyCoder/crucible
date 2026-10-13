#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/redirect/redirect -p
cd tmp/redirect/redirect || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require redirect/redirect

declare -a tests

tests=("redirect.redirect.to_file" "redirect.redirect.to_file_void")
tests+=("redirect.redirect.merge_all")
tests+=("redirect.redirect.text_to_error")
tests+=("redirect.redirect.text_to_file" "redirect.redirect.text_to_file_void")

function redirect.redirect.to_file {
    intro "redirect.redirect.to_file"
    redirect.to_file "echo hello" out.txt
    assert_equals "hello" "$(cat out.txt)" "output was not written to the file"
    success
}

function redirect.redirect.to_file_void {
    intro "redirect.redirect.to_file_void"
    assert_equals "" "$(redirect.to_file_void "echo hello")" "output was not discarded"
    success
}

function redirect.redirect.merge_all {
    intro "redirect.redirect.merge_all"
    local output
    output="$(redirect.merge_all "ls /crucible/does/not/exist")"
    test -n "$output" || fail "stderr was not merged into stdout"
    success
}

function redirect.redirect.text_to_error {
    intro "redirect.redirect.text_to_error"
    assert_equals "" "$(redirect.text_to_error "oops" 2>/dev/null)" "text ended up on stdout"
    assert_equals "oops" "$(redirect.text_to_error "oops" 2>&1 >/dev/null)" "text did not end up on stderr"
    success
}

function redirect.redirect.text_to_file {
    intro "redirect.redirect.text_to_file"
    redirect.text_to_file "hello" out.txt
    assert_equals "hello" "$(cat out.txt)" "text was not written to the file"
    redirect.text_to_file "again" out.txt
    assert_equals "again" "$(cat out.txt)" "file was not overwritten"
    success
}

function redirect.redirect.text_to_file_void {
    intro "redirect.redirect.text_to_file_void"
    assert_equals "" "$(redirect.text_to_file_void "hello")" "text was not discarded"
    success
}

echo "Testing redirect/redirect"

for test in "${tests[@]}"; do
    "$test"
done

teardown
