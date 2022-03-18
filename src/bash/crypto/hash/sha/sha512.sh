#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging
require strings/strings

function crypto.hash.sha512sum {
    __verify_nr_args "$#" 1 crypto.hash.sha512sum
    local target _hash pos
	target="$1"
    _hash=""
	if __command_exists "sha512sum"
    then
        _hash="$(sha512sum $target)"
        pos="$(strings.lindex "$_hash" " ")"
        _hash="$(strings.slice "$_hash" 0 $pos)"
    else
        logging.warning "[sha512sum] command not available, cannot determine SHA512 hash of $target"
    fi
    echo $_hash
}

function crypto.hash.sha512sum_check {
    __verify_nr_args "$#" 1 crypto.hash.sha512sum_check
    local checksum_file result
	checksum_file="$1"
    result=1
	if __command_exists "sha512sum"
    then
        sha512sum --check "$checksum_file" --quiet --status 2>/dev/null
        result=$?
    else
        logging.warning "[sha512sum] command not available, cannot use $checksum_file to determine checksums"
    fi
    __to_boolean "$result" "==" 0
}

function crypto.hash.binary_sha512sum {
    __verify_nr_args "$#" 1 crypto.hash.binary_sha512sum
    local target _hash pos
	target="$1"
    _hash=""
	if __command_exists "sha512sum"
    then
        _hash="$(sha512sum -b $target)"
        pos="$(strings.lindex "$_hash" " ")"
        _hash="$(strings.slice "$_hash" 0 $pos)"
    else
        logging.warning "[sha512sum] command not available, cannot determine SHA512 hash of $target"
    fi
    echo $_hash
}

function crypto.hash.binary_sha512sum_check {
    __verify_nr_args "$#" 1 crypto.hash.binary_sha512sum_check
    local checksum_file result
	checksum_file="$1"
    result=1
	if __command_exists "sha512sum"
    then
        sha512sum -b --check "$checksum_file" --quiet --status 2>/dev/null
        result=$?
    else
        logging.warning "[sha512sum] command not available, cannot use $checksum_file to determine checksums"
    fi
    __to_boolean "$result" "==" 0
}

# SHA512/224

function crypto.hash.sha512_224sum {
    __verify_nr_args "$#" 1 crypto.hash.sha512_224sum
    local target _hash pos
	target="$1"
    _hash=""
	if __command_exists "shasum"
    then
        _hash="$(shasum -a 512224 $target)"
        pos="$(strings.lindex "$_hash" " ")"
        _hash="$(strings.slice "$_hash" 0 $pos)"
    else
        logging.warning "[shasum] command not available, cannot determine SHA512/224 hash of $target"
    fi
    echo $_hash
}

function crypto.hash.sha512_224sum_check {
    __verify_nr_args "$#" 1 crypto.hash.sha512_224sum_check
    local checksum_file result
	checksum_file="$1"
    result=1
	if __command_exists "shasum"
    then
        shasum -a 512224 --check "$checksum_file" --quiet --status 2>/dev/null
        result=$?
    else
        logging.warning "[shasum] command not available, cannot use $checksum_file to determine checksums"
    fi
    __to_boolean "$result" "==" 0
}

function crypto.hash.binary_sha512_224sum {
    __verify_nr_args "$#" 1 crypto.hash.binary_sha512_224sum
    local target _hash pos
	target="$1"
    _hash=""
	if __command_exists "shasum"
    then
        _hash="$(shasum -a 512224 -b $target)"
        pos="$(strings.lindex "$_hash" " ")"
        _hash="$(strings.slice "$_hash" 0 $pos)"
    else
        logging.warning "[shasum] command not available, cannot determine SHA512/224 hash of $target"
    fi
    echo $_hash
}

function crypto.hash.binary_sha512_224sum_check {
    __verify_nr_args "$#" 1 crypto.hash.binary_sha512_224sum_check
    local checksum_file result
	checksum_file="$1"
    result=1
	if __command_exists "shasum"
    then
        shasum -a 512224 -b --check "$checksum_file" --quiet --status 2>/dev/null
        result=$?
    else
        logging.warning "[shasum] command not available, cannot use $checksum_file to determine checksums"
    fi
    __to_boolean "$result" "==" 0
}

# SHA512/256

function crypto.hash.sha512_256sum {
    __verify_nr_args "$#" 1 crypto.hash.sha512_256sum
    local target _hash pos
	target="$1"
    _hash=""
	if __command_exists "shasum"
    then
        _hash="$(shasum -a 512256 $target)"
        pos="$(strings.lindex "$_hash" " ")"
        _hash="$(strings.slice "$_hash" 0 $pos)"
    else
        logging.warning "[shasum] command not available, cannot determine SHA512/256 hash of $target"
    fi
    echo $_hash
}

function crypto.hash.sha512_256sum_check {
    __verify_nr_args "$#" 1 crypto.hash.sha512_256sum_check
    local checksum_file result
	checksum_file="$1"
    result=1
	if __command_exists "shasum"
    then
        shasum -a 512256 --check "$checksum_file" --quiet --status 2>/dev/null
        result=$?
    else
        logging.warning "[shasum] command not available, cannot use $checksum_file to determine checksums"
    fi
    __to_boolean "$result" "==" 0
}

function crypto.hash.binary_sha512_256sum {
    __verify_nr_args "$#" 1 crypto.hash.binary_sha512_256sum
    local target _hash pos
	target="$1"
    _hash=""
	if __command_exists "shasum"
    then
        _hash="$(shasum -a 512256 -b $target)"
        pos="$(strings.lindex "$_hash" " ")"
        _hash="$(strings.slice "$_hash" 0 $pos)"
    else
        logging.warning "[shasum] command not available, cannot determine SHA512/256 hash of $target"
    fi
    echo $_hash
}

function crypto.hash.binary_sha512_256sum_check {
    __verify_nr_args "$#" 1 crypto.hash.binary_sha512_256sum_check
    local checksum_file result
	checksum_file="$1"
    result=1
	if __command_exists "shasum"
    then
        shasum -a 512256 -b --check "$checksum_file" --quiet --status 2>/dev/null
        result=$?
    else
        logging.warning "[shasum] command not available, cannot use $checksum_file to determine checksums"
    fi
    __to_boolean "$result" "==" 0
}