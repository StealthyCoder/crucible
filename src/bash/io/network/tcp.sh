#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require io/network/.internal
require logging/logging

# Sends the data followed by a newline, escape sequences like \r\n are interpreted
function network.tcp.send {
	__verify_nr_args "$#" 2 network.tcp.send
	local fd data
	fd="$1"
	data="$2"
	echo -e "$data" >&"$fd"
}

# Sends the data exactly as given, escape sequences like \r\n are interpreted
# but nothing is appended
function network.tcp.send_raw {
	__verify_nr_args "$#" 2 network.tcp.send_raw
	local fd data
	fd="$1"
	data="$2"
	printf '%b' "$data" >&"$fd"
}

# Reads until the other side closes the connection. The timeout in seconds is
# how long the connection may stay silent, CRUCIBLE_NETWORK_TIMEOUT is the
# default and no timeout is used when neither is given.
# Text only, bash cannot hold NUL bytes so those are left out.
function network.tcp.receive {
	if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
		logging.error "network.tcp.receive: usage is network.tcp.receive <FD> [TIMEOUT]"
		exit 1
	fi
	local fd chunk response timeout_seconds
	local -a timeout_args
	fd="$1"
	timeout_seconds="${2:-${CRUCIBLE_NETWORK_TIMEOUT:-0}}"
	timeout_args=()
	if [[ "$timeout_seconds" != "0" ]]; then
		timeout_args=(-t "$timeout_seconds")
	fi
	response=""
	while IFS= read -r "${timeout_args[@]}" -N 65536 -u "$fd" chunk; do
		response+="$chunk"
	done
	response+="$chunk"
	printf '%s\n' "$response"
}

# Reads exactly <COUNT> bytes and prints them as hexadecimal digits, NUL bytes included.
function network.tcp.receive_hex {
	if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
		logging.error "network.tcp.receive_hex: usage is network.tcp.receive_hex <FD> <COUNT> [TIMEOUT]"
		exit 1
	fi
	__read_bytes_hex "$1" "$2" "${3:-${CRUCIBLE_NETWORK_TIMEOUT:-0}}"
}

# Sends bytes that are given as hexadecimal digits, for example 0A1B
function network.tcp.send_hex {
	__verify_nr_args "$#" 2 network.tcp.send_hex
	network._send_hex "$1" "$2"
}

function network.tcp.close {
	__verify_nr_args "$#" 1 network.tcp.close
	network._close "$1"
}

function network.tcp {
	# switch on number of arguments
	# Minimum is two:
	#  on 2 - host and port we only do setup
	#  on 3 - we do immediate host, port and send data and retrieve
	#  on 4+ - we log warning that surplus is ignored
	case "$#" in
	0 | 1)
		network._usage tcp
		exit 1
		;;
	2)
		network._connect tcp "$1" "$2" CRUCIBLE_NETWORK_FD || return 1
		export CRUCIBLE_NETWORK_FD
		logging.debug "Exported CRUCIBLE_NETWORK_FD to value: $CRUCIBLE_NETWORK_FD"
		;;
	*)
		if [ "$#" -gt 3 ]; then
			logging.warning "Ignoring surplus: ${*:4}"
		fi
		local fd
		network._connect tcp "$1" "$2" fd || return 1
		network.tcp.send "$fd" "$3"
		network.tcp.receive "$fd" "${CRUCIBLE_NETWORK_TIMEOUT:-10}"
		network.tcp.close "$fd"
		;;
	esac
}
