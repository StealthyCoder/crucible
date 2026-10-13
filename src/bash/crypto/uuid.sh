#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.3.0
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1791901074
### CRUCIBLE META DATA ###

require core/.internal
require arrays/arrays
require strings/strings

# Version 4 uuid, the random bytes are read from /dev/urandom by bash itself
function crypto.uuid.uuidv4 {
	local uuid fd hex variant
	exec {fd}</dev/urandom
	__read_bytes_hex "$fd" 16
	hex="$__READ_HEX"
	exec {fd}<&-
	if [ "${#hex}" -ne 32 ]; then
		logging.error "Could not read random bytes from /dev/urandom"
		return 1
	fi
	arrays.transform_into_array parts
	arrays.add parts "$(strings.slice "$hex" 0 8)"
	arrays.add parts "$(strings.slice "$hex" 8 4)"
	arrays.add parts "$(strings.concat 4 "$(strings.slice "$hex" 13 3)")"
	# RFC 4122 variant: the first digit of the fourth group has to be 8, 9, a or b
	variant="$(strings.slice 89AB $((16#$(strings.slice "$hex" 16 1) % 4)) 1)"
	arrays.add parts "$(strings.concat "$variant" "$(strings.slice "$hex" 17 3)")"
	arrays.add parts "$(strings.slice "$hex" 20 12)"
	uuid="$(strings.join parts -)"
	unset parts
	echo "${uuid,,}"
}
