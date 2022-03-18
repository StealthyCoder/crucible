#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require arrays/arrays
require crypto/hash/sha/safe/sha256
require io/binary/safe
require pipes/pipes

function crypto.uuid.uuidv4 {
    local uuid bytes _hash
    arrays.transform_into_array parts
    bytes="$(binary.random_bytes 1K)"
    _hash="$(crypto.hash.binary_sha256sum_from_bytes "$bytes")"
    arrays.add parts "$(strings.slice $_hash 0 8)"
    arrays.add parts "$(strings.slice $_hash 8 4)"
    arrays.add parts 4
    arrays.add parts "$(strings.slice $_hash 13 3)"
    arrays.add parts "$(strings.slice $_hash 16 4)"
    arrays.add parts "$(strings.slice $_hash 20 12)"
    uuid="$(arrays.get parts 0)-$(arrays.get parts 1)-$(arrays.get parts 2)$(arrays.get parts 3)-$(arrays.get parts 4)-$(arrays.get parts 5)"
    unset parts
    echo "$uuid"
}