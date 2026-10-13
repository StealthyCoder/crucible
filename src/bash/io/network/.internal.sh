#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.3.0
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1791901074
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging

function network.verify_host {
	__verify_nr_args "$#" 1 network.verify_host
	local host octet
	host="$1"
	if [[ "$host" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
		for octet in "${BASH_REMATCH[@]:1}"; do
			if [ "$octet" -gt 255 ]; then
				return 1
			fi
		done
		return 0
	fi
	# One or more labels of letters, digits and inner hyphens, separated by dots
	if [ "${#host}" -le 253 ] && [[ "$host" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.?$ ]]; then
		return 0
	fi
	return 1
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

function network.verify_fd {
	__verify_nr_args "$#" 1 network.verify_fd
	[[ "$1" =~ ^[0-9]+$ ]] && [ -e "/proc/$$/fd/$1" ]
}

# Opens a connection and stores the number of the file descriptor in the
# variable named by the fourth argument. The locals have unusual names on
# purpose, a caller passing the name of one of them would otherwise set the local.
function network._connect {
	__verify_nr_args "$#" 4 network._connect
	local _connect_protocol _connect_host _connect_port _connect_variable _connect_fd
	_connect_protocol="$1"
	_connect_host="$2"
	_connect_port="$3"
	_connect_variable="$4"
	if ! network.verify_host "$_connect_host"; then
		logging.error "Invalid hostname: $_connect_host"
		exit 1
	fi
	if ! network.verify_port "$_connect_port"; then
		logging.error "Invalid port: $_connect_port"
		exit 1
	fi
	if ! { exec {_connect_fd}<>"/dev/$_connect_protocol/$_connect_host/$_connect_port"; } 2>/dev/null; then
		logging.error "Could not connect to $_connect_host:$_connect_port over $_connect_protocol"
		return 1
	fi
	printf -v "$_connect_variable" '%s' "$_connect_fd"
}

# Writes bytes that are given as hexadecimal digits, for example 0A1B
function network._send_hex {
	__verify_nr_args "$#" 2 network._send_hex
	local fd hex format i
	fd="$1"
	hex="$2"
	if ! [[ "$hex" =~ ^([0-9a-fA-F]{2})*$ ]]; then
		logging.error "Expected an even number of hexadecimal digits, got: $hex"
		exit 1
	fi
	format=""
	for ((i = 0; i < ${#hex}; i += 2)); do
		format+="\\x${hex:i:2}"
	done
	# shellcheck disable=SC2059
	printf "$format" >&"$fd"
}

function network._close {
	__verify_nr_args "$#" 1 network._close
	local fd
	fd="$1"
	if ! [[ "$fd" =~ ^[0-9]+$ ]]; then
		logging.error "Invalid file descriptor: $fd"
		exit 1
	fi
	eval "exec $fd>&-"
	if [ "${CRUCIBLE_NETWORK_FD:-}" = "$fd" ]; then
		unset CRUCIBLE_NETWORK_FD
	fi
}

# Usage: network._usage <protocol>
function network._usage {
	logging.error "network.$1: Wrong number of arguments, need at least 2 or 3."
	logging.error "network.$1: usage is network.$1 <HOST> <PORT>"
	logging.error "to setup a file descriptor to send messages"
	logging.error "network.$1: usage is network.$1 <HOST> <PORT> <DATA>"
	logging.error "to send one message and immediately get response"
}
