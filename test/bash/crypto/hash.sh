#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/crypto/hash -p
cd tmp/crypto/hash || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require crypto/hash

declare -a tests
declare -A vectors

# Hashes of "hello" followed by a newline, calculated with the system tools
vectors=(
    [md5]="b1946ac92492d2347c6235b4d2611184"
    [sha224]="2d6d67d91d0badcdd06cbbba1fe11538a68a37ec9c2e26457ceff12b"
    [sha256]="5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03"
    [sha384]="1d0f284efe3edea4b9ca3bd514fa134b17eae361ccc7a1eefeff801b9bd6604e01f21f6bf249ef030599f0c218f2ba8c"
    [sha512]="e7c22b994c59d9cf2b48e549b1e24666636045930d3da7c1acb299d1c3b7f931f94aae41edda2c2b207a36e10f8bcb8d45223e54878f5b316e7ce3b6bc019629"
    [sha512_224]="4d32058e76908e46640feeaf6e3f47ca6c124e971745748aa0ce8f7a"
    [sha512_256]="7f3f0c0d5219f51459578305ed2bbc198588758da85d08024c79c1195d1cd611"
)

# Which tool writes a checksum file for which algorithm
declare -A tools
tools=(
    [md5]="md5sum"
    [sha224]="sha224sum"
    [sha256]="sha256sum"
    [sha384]="sha384sum"
    [sha512]="sha512sum"
    [sha512_224]="shasum -a 512224"
    [sha512_256]="shasum -a 512256"
)

tests=("crypto.hash.files" "crypto.hash.text" "crypto.hash.checks")
tests+=("crypto.hash.paths_with_spaces")
# The safe variants replace the functions above, so they have to come last
tests+=("crypto.hash.safe")

function crypto.hash.files {
    intro "crypto.hash: hashing a file"
    local algo
    printf 'hello\n' >hello.txt
    for algo in "${!vectors[@]}"; do
        assert_equals "${vectors[$algo]}" "$("crypto.hash.${algo}sum" hello.txt)" "${algo}sum"
        assert_equals "${vectors[$algo]}" "$("crypto.hash.binary_${algo}sum" hello.txt)" "binary_${algo}sum"
    done
    rm hello.txt
    success
}

function crypto.hash.text {
    intro "crypto.hash: hashing text"
    local algo
    for algo in "${!vectors[@]}"; do
        [ "$algo" = "md5" ] && continue
        assert_equals "${vectors[$algo]}" "$("crypto.hash.${algo}sum_from_text" hello)" "${algo}sum_from_text"
        assert_equals "${vectors[$algo]}" "$("crypto.hash.binary_${algo}sum_from_bytes" hello)" "binary_${algo}sum_from_bytes"
    done
    success
}

function crypto.hash.checks {
    intro "crypto.hash: verifying checksum files"
    local algo
    printf 'hello\n' >hello.txt
    for algo in "${!vectors[@]}"; do
        ${tools[$algo]} hello.txt >sums.txt
        assert_true "${algo}sum_check rejects a good file" "crypto.hash.${algo}sum_check" sums.txt
        assert_true "binary_${algo}sum_check rejects a good file" "crypto.hash.binary_${algo}sum_check" sums.txt
    done
    for algo in "${!vectors[@]}"; do
        ${tools[$algo]} hello.txt >sums.txt
        echo "tampered" >hello.txt
        assert_false "${algo}sum_check accepts a changed file" "crypto.hash.${algo}sum_check" sums.txt
        printf 'hello\n' >hello.txt
    done
    rm hello.txt sums.txt
    success
}

function crypto.hash.paths_with_spaces {
    intro "crypto.hash: file names containing spaces"
    printf 'hello\n' >"hello world.txt"
    assert_equals "${vectors[md5]}" "$(crypto.hash.md5sum "hello world.txt")" "md5sum"
    assert_equals "${vectors[sha256]}" "$(crypto.hash.sha256sum "hello world.txt")" "sha256sum"
    assert_equals "${vectors[sha512]}" "$(crypto.hash.binary_sha512sum "hello world.txt")" "binary_sha512sum"
    rm "hello world.txt"
    success
}

function crypto.hash.safe {
    intro "crypto.hash.safe: same hashes through shasum"
    require crypto/hash/safe
    local algo
    printf 'hello\n' >hello.txt
    for algo in sha224 sha256 sha384 sha512; do
        assert_equals "${vectors[$algo]}" "$("crypto.hash.${algo}sum" hello.txt)" "safe ${algo}sum"
        assert_equals "${vectors[$algo]}" "$("crypto.hash.binary_${algo}sum" hello.txt)" "safe binary_${algo}sum"
        assert_equals "${vectors[$algo]}" "$("crypto.hash.${algo}sum_from_text" hello)" "safe ${algo}sum_from_text"
        assert_equals "${vectors[$algo]}" "$("crypto.hash.binary_${algo}sum_from_bytes" hello)" "safe binary_${algo}sum_from_bytes"
        ${tools[$algo]} hello.txt >sums.txt
        assert_true "safe ${algo}sum_check rejects a good file" "crypto.hash.${algo}sum_check" sums.txt
        assert_true "safe binary_${algo}sum_check rejects a good file" "crypto.hash.binary_${algo}sum_check" sums.txt
    done
    rm hello.txt sums.txt
    success
}

echo "Testing crypto/hash"

for test in "${tests[@]}"; do
    "$test"
done

teardown
