#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require io/binary/binary

function binary.read_file {
	__verify_nr_args "$#" 1 binary.read_file
	local target
	target="$1"
	if [ -f "$target" ]; then
		if __command_exists "file"; then
			if binary.is_printable "$target"; then
				cat "$target"
			fi
		fi
	fi
}

function binary.write_file {
	__verify_nr_args "$#" 2 binary.write_file
	local content target
	content="$1"
	target="$2"
	if [ ! -f "$target" ]; then
		echo "$content" >"$target"
	fi
}

function binary.extract_strings {
	__verify_nr_args "$#" 1 binary.extract_strings
	local target content
	target="$1"
	content=""
	if binary.is_binary "$target"; then
		if __command_exists "strings"; then
			content="$(strings -d $target)"
		else
			logging.warning "[strings] command does not exist, cannot determine extract strings from $target"
		fi
	else
		logging.warning "$target is not a binary file"
	fi
	echo "$content"
}

function binary.random_bytes {
	__verify_nr_args "$#" 1 binary.random_bytes
	local size content
	size="$1"
	content=""
	if [[ "$size" =~ [0-9]+[K]?$ ]]; then
		if [ "$(strings.replace_char_with $size 'K' '')" -gt 10240 ]; then
			logging.warning "$size is too large, has to be fewer than or equal to 10240 for both bytes and Kibibytes"
		else
			content="$(head -c $size </dev/urandom)"
		fi
	else
		logging.warning "$size is too large, has to be in bytes (no suffix) or Kibibyte (K) range"
	fi
	echo "$content"
}

function binary.write_file_void {
	__verify_nr_args "$#" 1 binary.write_file_void
	local content
	content="$1"
	echo "$content" >/dev/null
}
