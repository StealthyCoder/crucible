#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.3.0
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1791901074
### CRUCIBLE META DATA ###

require core/.internal
require io/network/.internal
require logging/logging

# Sends the data as one datagram followed by a newline, escape sequences like \n are interpreted
function network.udp.send {
	__verify_nr_args "$#" 2 network.udp.send
	local fd data
	fd="$1"
	data="$2"
	echo -e "$data" >&"$fd"
}

# Sends a datagram that is given as hexadecimal digits, for example 0A1B
function network.udp.send_hex {
	__verify_nr_args "$#" 2 network.udp.send_hex
	network._send_hex "$1" "$2"
}

# Waits for a datagram and prints it, or fails when the timeout in seconds
# passes, CRUCIBLE_NETWORK_TIMEOUT is the default and 5 seconds the fallback.
# Text only: bash cannot hold NUL bytes so those are left out, and a datagram
# cannot be read piece by piece because the rest of it is lost. Read binary
# data over TCP instead.
function network.udp.receive {
	if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
		logging.error "network.udp.receive: usage is network.udp.receive <FD> [TIMEOUT]"
		exit 1
	fi
	local LC_ALL=C
	local fd timeout_seconds polls datagram
	fd="$1"
	timeout_seconds="${2:-${CRUCIBLE_NETWORK_TIMEOUT:-5}}"
	# Polls for 50 milliseconds at a time, that is the longest a datagram waits to be picked up
	polls=$(((${timeout_seconds%.*} + 0) * 20))
	if [ "$polls" -lt 1 ]; then
		polls=1
	fi
	while [ "$polls" -gt 0 ]; do
		IFS= read -r -t 0.05 -N 65535 -u "$fd" datagram
		if [ -n "$datagram" ]; then
			printf '%s' "$datagram"
			return 0
		fi
		polls=$((polls - 1))
	done
	return 1
}

function network.udp.close {
	__verify_nr_args "$#" 1 network.udp.close
	network._close "$1"
}

function network.udp {
	# switch on number of arguments
	# Minimum is two:
	#  on 2 - host and port we only do setup
	#  on 3 - we do immediate host, port and send data and retrieve
	#  on 4+ - we log warning that surplus is ignored
	case "$#" in
	0 | 1)
		network._usage udp
		exit 1
		;;
	2)
		network._connect udp "$1" "$2" CRUCIBLE_NETWORK_FD || return 1
		export CRUCIBLE_NETWORK_FD
		logging.debug "Exported CRUCIBLE_NETWORK_FD to value: $CRUCIBLE_NETWORK_FD"
		;;
	*)
		if [ "$#" -gt 3 ]; then
			logging.warning "Ignoring surplus: ${*:4}"
		fi
		local fd
		network._connect udp "$1" "$2" fd || return 1
		network.udp.send "$fd" "$3"
		network.udp.receive "$fd"
		network.udp.close "$fd"
		;;
	esac
}
