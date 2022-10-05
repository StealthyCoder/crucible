#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal

function network.verify_host {
	__verify_nr_args "$#" 1 network.verify_host
	local host
	host="$1"
	if [[ "$host" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		true
	elif [[ "$host" =~ ^[a-zA-Z0-9.]*$ ]]; then
		true
	else
		false
	fi
}

function network.verify_port {
	__verify_nr_args "$#" 1 network.verify_port
	local port
	port="$1"
	if [[ "$port" =~ ^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$ ]]; then
		true
	else
		false
	fi
}
