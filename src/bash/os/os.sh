#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging

function os.get_architecture {
	if __command_exists "uname"; then
		uname -m
	else
		logging.warning "[uname] command does not exist, unable to get architecture"
	fi
}
