#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging
require strings/strings

function crypto.hash.sha384sum {
    __verify_nr_args "$#" 1 crypto.hash.sha384sum
    local target _hash pos
	target="$1"
    _hash=""
	if __command_exists "sha384sum"
    then
        _hash="$(sha384sum $target)"
        pos="$(strings.lindex "$_hash" " ")"
        _hash="$(strings.slice "$_hash" 0 $pos)"
    else
        logging.warning "[sha384sum] command not available, cannot determine sha384 hash of $target"
    fi
    echo $_hash
}

function crypto.hash.sha384sum_check {
    __verify_nr_args "$#" 1 crypto.hash.sha384sum_check
    local checksum_file result
	checksum_file="$1"
    result=1
	if __command_exists "sha384sum"
    then
        sha384sum --check "$checksum_file" --quiet --status 2>/dev/null
        result=$?
    else
        logging.warning "[sha384sum] command not available, cannot use $checksum_file to determine checksums"
    fi
    __to_boolean "$result" "==" 0
}

function crypto.hash.binary_sha384sum {
    __verify_nr_args "$#" 1 crypto.hash.binary_sha384sum
    local target _hash pos
	target="$1"
    _hash=""
	if __command_exists "sha384sum"
    then
        _hash="$(sha384sum -b $target)"
        pos="$(strings.lindex "$_hash" " ")"
        _hash="$(strings.slice "$_hash" 0 $pos)"
    else
        logging.warning "[sha384sum] command not available, cannot determine sha384 hash of $target"
    fi
    echo $_hash
}

function crypto.hash.binary_sha384sum_check {
    __verify_nr_args "$#" 1 crypto.hash.binary_sha384sum_check
    local checksum_file result
	checksum_file="$1"
    result=1
	if __command_exists "sha384sum"
    then
        sha384sum -b --check "$checksum_file" --quiet --status 2>/dev/null
        result=$?
    else
        logging.warning "[sha384sum] command not available, cannot use $checksum_file to determine checksums"
    fi
    __to_boolean "$result" "==" 0
}