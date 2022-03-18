#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require arrays/arrays
require crypto/hash/sha/safe/sha256
require io/binary/safe

function crypto.uuid.uuidv4 {
	local uuid bytes _hash
	arrays.transform_into_array parts
	bytes="$(binary.random_bytes 1K)"
	_hash="$(crypto.hash.binary_sha256sum_from_bytes "$bytes")"
	arrays.add parts "$(strings.slice $_hash 0 8)"
	arrays.add parts "$(strings.slice $_hash 8 4)"
	arrays.add parts "$(strings.concat 4 $(strings.slice $_hash 13 3))"
	arrays.add parts "$(strings.slice $_hash 16 4)"
	arrays.add parts "$(strings.slice $_hash 20 12)"
	uuid="$(strings.join parts -)"
	unset parts
	echo "$uuid"
}
