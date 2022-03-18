#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging
require strings/strings

function crypto.hash.md5sum {
    __verify_nr_args "$#" 1 crypto.hash.md5sum
    local target _hash pos
	target="$1"
    _hash=""
	if __command_exists "md5sum"
    then
        _hash="$(md5sum $target)"
        pos="$(strings.lindex "$_hash" " ")"
        _hash="$(strings.slice "$_hash" 0 $pos)"
    else
        logging.warning "[md5sum] command not available, cannot determine md5 hash of $target"
    fi
    echo $_hash
}

function crypto.hash.md5sum_check {
    __verify_nr_args "$#" 1 crypto.hash.md5sum_check
    local checksum_file result
	checksum_file="$1"
    result=1
	if __command_exists "md5sum"
    then
        md5sum --check "$checksum_file" --quiet --status 2>/dev/null
        result=$?
    else
        logging.warning "[md5sum] command not available, cannot use $checksum_file to determine checksums"
    fi
    __to_boolean "$result" "==" 0
}

function crypto.hash.binary_md5sum {
    __verify_nr_args "$#" 1 crypto.hash.binary_md5sum
    local target _hash pos
	target="$1"
    _hash=""
	if __command_exists "md5sum"
    then
        _hash="$(md5sum -b $target)"
        pos="$(strings.lindex "$_hash" " ")"
        _hash="$(strings.slice "$_hash" 0 $pos)"
    else
        logging.warning "[md5sum] command not available, cannot determine md5 hash of $target"
    fi
    echo $_hash
}

function crypto.hash.binary_md5sum_check {
    __verify_nr_args "$#" 1 crypto.hash.binary_md5sum_check
    local checksum_file result
	checksum_file="$1"
    result=1
	if __command_exists "md5sum"
    then
        md5sum -b --check "$checksum_file" --quiet --status 2>/dev/null
        result=$?
    else
        logging.warning "[md5sum] command not available, cannot use $checksum_file to determine checksums"
    fi
    __to_boolean "$result" "==" 0
}