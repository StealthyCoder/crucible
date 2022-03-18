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
	$execute >"$target"
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
	$execute 2>&1
}

function redirect.text_to_error {
	__verify_nr_args "$#" 1 redirect.text_to_error
	local content
	content="$1"
	echo "$content" 1>&2
}

function redirect.text_to_file {
	__verify_nr_args "$#" 2 redirect.text_to_file
	local content target
	content="$1"
	target="$2"
	echo "$content" >"$target"
}

function redirect.text_to_file_void {
	__verify_nr_args "$#" 1 redirect.text_to_file_void
	local content
	content="$1"
	redirect.text_to_file "$content" /dev/null
}
