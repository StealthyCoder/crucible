#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal

function redirect.to_file {
	__verify_nr_args "$#" 2 redirect.to_file
	local execute target
	execute="$1"
	target="$2"
	echo "$($execute >$target)"
}

function redirect.to_file_void {
	__verify_nr_args "$#" 1 redirect.to_file_void
	local execute
	execute="$1"
	redirect.to_file "$execute" /dev/null
}

function redirect.merge_all {
	__verify_nr_args "$#" 1 redirect.merge_all
	local execute
	execute="$1"
	echo "$($execute 2>&1)"
}
