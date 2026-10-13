#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/crypto/uuid -p
cd tmp/crypto/uuid || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require crypto/uuid

declare -a tests

tests=("crypto.uuid.format" "crypto.uuid.unique")

function crypto.uuid.format {
    intro "crypto.uuid.uuidv4 has the shape of an RFC 4122 version 4 uuid"
    local uuid
    for _ in $(seq 1 25); do
        uuid="$(crypto.uuid.uuidv4)"
        [[ "$uuid" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]] || fail "Not a valid v4 uuid: $uuid"
    done
    success
}

function crypto.uuid.unique {
    intro "crypto.uuid.uuidv4 does not repeat itself"
    local duplicates uuid
    declare -A seen
    duplicates=0
    for _ in $(seq 1 25); do
        uuid="$(crypto.uuid.uuidv4)"
        if [ -n "${seen[$uuid]+_}" ]; then
            duplicates=$((duplicates + 1))
        fi
        seen[$uuid]=1
    done
    assert_equals "0" "$duplicates" "Duplicate uuids generated"
    success
}

echo "Testing crypto/uuid"

for test in "${tests[@]}"; do
    "$test"
done

teardown
