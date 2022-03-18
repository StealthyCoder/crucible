#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal

function pipes.pipe_to {
	__verify_nr_args "$#" 2 pipes.pipe_to
	local execute target
	execute="$1"
	target="$2"
	$execute | $target -
}

function pipes.pipe_text_to {
	__verify_nr_args "$#" 2 pipes.pipe_text_to
	local content target
	content="$1"
	target="$2"
	echo "$content" | $target
}
