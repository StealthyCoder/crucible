#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require crypto/hash/sha/sha256
require redirect/redirect

function crypto.hash.sha256sum {
	__verify_nr_args "$#" 1 crypto.hash.sha256sum
	local target _hash pos
	target="$1"
	_hash=""
	if __command_exists "shasum"; then
		_hash="$(shasum -a 256 --UNIVERSAL $target)"
		pos="$(strings.lindex "$_hash" " ")"
		_hash="$(strings.slice "$_hash" 0 $pos)"
	else
		redirect.text_to_error "$(logging.warning "[shasum] command not available, cannot determine sha256 hash of $target")"
		exit 1
	fi
	echo $_hash
}

function crypto.hash.sha256sum_from_text {
	__verify_nr_args "$#" 1 crypto.hash.sha256sum_from_text
	local target _hash pos
	target="$1"
	_hash=""
	if __command_exists "shasum"; then
		_hash="$(echo "$target" | shasum -a 256 --UNIVERSAL)"
		pos="$(strings.lindex "$_hash" " ")"
		_hash="$(strings.slice "$_hash" 0 $pos)"
	else
		redirect.text_to_error "$(logging.warning "[shasum] command not available, cannot determine sha256 hash of $target")"
		exit 1
	fi
	echo $_hash
}

function crypto.hash.sha256sum_check {
	__verify_nr_args "$#" 1 crypto.hash.sha256sum_check
	local checksum_file result
	checksum_file="$1"
	result=1
	if __command_exists "shasum"; then
		shasum -a 256 --UNIVERSAL --check "$checksum_file" --quiet --status 2>/dev/null
		result=$?
	else
		redirect.text_to_error "$(logging.warning "[shasum] command not available, cannot use $checksum_file to determine checksums")"
		exit 1
	fi
	__to_boolean "$result" "==" 0
}

function crypto.hash.binary_sha256sum {
	__verify_nr_args "$#" 1 crypto.hash.binary_sha256sum
	local target _hash pos
	target="$1"
	_hash=""
	if __command_exists "shasum"; then
		_hash="$(shasum -a 256 --UNIVERSAL "$target")"
		pos="$(strings.lindex "$_hash" " ")"
		_hash="$(strings.slice "$_hash" 0 $pos)"
	else
		redirect.text_to_error "$(logging.warning "[shasum] command not available, cannot determine sha256 hash of $target")"
		exit 1
	fi
	echo $_hash
}

function crypto.hash.binary_sha256sum_from_bytes {
	__verify_nr_args "$#" 1 crypto.hash.binary_sha256sum_from_bytes
	local target _hash pos
	target="$1"
	_hash=""
	if __command_exists "shasum"; then
		_hash="$(echo "$target" | shasum -a 256 --UNIVERSAL)"
		pos="$(strings.lindex "$_hash" " ")"
		_hash="$(strings.slice "$_hash" 0 $pos)"
	else
		redirect.text_to_error "$(logging.warning "[shasum] command not available, cannot determine sha256 hash of $target")"
		exit 1
	fi
	echo $_hash
}

function crypto.hash.binary_sha256sum_check {
	__verify_nr_args "$#" 1 crypto.hash.binary_sha256sum_check
	local checksum_file result
	checksum_file="$1"
	result=1
	if __command_exists "shasum"; then
		shasum -a 256 --UNIVERSAL --check "$checksum_file" --quiet --status 2>/dev/null
		result=$?
	else
		redirect.text_to_error "$(logging.warning "[shasum] command not available, cannot use $checksum_file to determine checksums")"
		exit 1
	fi
	__to_boolean "$result" "==" 0
}
