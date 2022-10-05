#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require io/network/.internal
require logging/logging
require arrays/arrays

function network.udp.send {
	__verify_nr_args "$#" 2 network.udp_send
	local fd data
	fd="$1"
	data="$2"
	echo -e "$data" >&$fd
}

function network.udp.receive {
	__verify_nr_args "$#" 1 network.udp_receive
	local fd response
	fd="$1"
	response=$(dd status=none count=1 <&$fd)
	echo "$response"
}

function network.udp {
	case "$#" in
	0 | 1)
		logging.error "network.udp: Wrong number of arguments, need at least 2 or 3."
		logging.error "network.udp: usage is network.udp <HOST> <PORT>"
		logging.error "to setup a file descriptor to send messages"
		logging.error "network.udp: usage is network.udp <HOST> <PORT> <DATA>"
		logging.error "to send one message and immediately get response"
		exit 1
		;;
	2)
		local host port
		host="$1"
		port="$2"
		if ! network.verify_host "$host"; then
			logging.error "Invalid hostname: $host"
			exit 1
		fi
		if ! network.verify_port "$port"; then
			logging.error "Invalid port: $port"
			exit 1
		fi
		local available_fd
		for fd in $(ls /proc/$$/fd); do
			if test "$fd" -lt 255; then
				available_fd="$fd"
			elif test "$fd" -eq 255; then
				available_fd="$(($available_fd + 1))"
			fi
		done
		eval "exec $available_fd<>/dev/udp/$host/$port"
		export CRUCIBLE_NETWORK_FD="$available_fd"
		logging.debug "Exported CRUCIBLE_NETWORK_FD to value: $available_fd"
		;;
	3)
		local host port data
		host="$1"
		port="$2"
		data="$3"
		if ! network.verify_host "$host"; then
			logging.error "Invalid hostname: $host"
			exit 1
		fi
		if ! network.verify_port "$port"; then
			logging.error "Invalid port: $port"
			exit 1
		fi
		local available_fd
		for fd in $(ls /proc/$$/fd); do
			if test "$fd" -lt 255; then
				available_fd="$fd"
			elif test "$fd" -eq 255; then
				available_fd="$(($available_fd + 1))"
			fi
		done
		eval "exec $available_fd<>/dev/udp/$host/$port"
		network.udp_send "$available_fd" "$data"
		echo "$(network.udp_receive "$available_fd")"
		;;
	*)
		arrays.transform_into_array args
		arrays.add_all args "$@"
		local surplus i
		surplus=""
		for ((i = 3; i < ${#args[@]}; i++)); do
			surplus+=" ${args[$i]}"
		done
		logging.warning "Ignoring surplus:$surplus"
		unset args
		local host port data
		host="$1"
		port="$2"
		data="$3"
		if ! network.verify_host "$host"; then
			logging.error "Invalid hostname: $host"
			exit 1
		fi
		if ! network.verify_port "$port"; then
			logging.error "Invalid port: $port"
			exit 1
		fi
		local available_fd
		for fd in $(ls /proc/$$/fd); do
			if test "$fd" -lt 255; then
				available_fd="$fd"
			elif test "$fd" -eq 255; then
				available_fd="$(($available_fd + 1))"
			fi
		done
		eval "exec $available_fd<>/dev/udp/$host/$port"
		network.udp_send "$available_fd" "$data"
		echo "$(network.udp_receive "$available_fd")"
		;;
	esac
}
