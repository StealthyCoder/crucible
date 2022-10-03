#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging
require arrays/arrays
require strings/strings


function network.verify_host {
	__verify_nr_args "$#" 1 network.verify_host
	local host
	host="$1"
	if [[ "$host" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
	then
		true
	elif [[ "$host" =~ ^[a-zA-Z0-9.]*$ ]]
	then
		true
	else
		false
	fi
}

function network.verify_port {
	__verify_nr_args "$#" 1 network.verify_port
	local port
	port="$1"
	if [[ "$port" =~ ^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$ ]]
	then
		true
	else
		false
	fi
}

function network.tcp_send {
	# verify args
	# first is file descriptor
	# second is data 
	# send
	true
}

function network.tcp_receive {
	# verify args
	# receive from file descriptor
	# return that data
	true
}

function network.tcp {
	# switch on number of arguments
	# Minimum is two:
	#  on 2 - host and port we only do setup
	#  on 3 - we do immediate host, port and send data and retrieve
	#  on 4+ - we log warning that surplus is ignored
	case "$#" in
		0|1)
			logging.error "network.tcp: Wrong number of arguments, need at least 2 or 3."
			logging.error "network.tcp: usage is network.tcp <HOST> <PORT>"
			logging.error "to setup a file descriptor to send messages"
			logging.error "network.tcp: usage is network.tcp <HOST> <PORT> <DATA>"
			logging.error "to send one message and immediately get response"
			exit 1
			;;
		2) 
			#	4. exec 3<>/dev/tcp/www.google.com/80
			# echo -e "GET / HTTP/1.1\r\nhost: http://www.google.com\r\nConnection: close\r\n\r\n" >&3
			# cat <&3
			local host port
			host="$1"
			port="$2"
			if ! network.verify_host "$host"
			then
				logging.error "Invalid hostname: $host"
				exit 1
			fi
			if ! network.verify_port "$port"
			then
				logging.error "Invalid port: $port"
				exit 1
			fi
			local available_fd
			for fd in $(ls /proc/$$/fd)
			do
				if test "$fd" -lt 255
				then
						available_fd="$fd"
				elif test "$fd" -eq 255
				then
					available_fd="$(($available_fd + 1))"
				fi
			done
			eval "exec $available_fd<>/dev/tcp/$host/$port"
			export CRUCIBLE_NETWORK_FD="$available_fd"
		;;
		3) 
			logging.info "Do setup"
			logging.info "Send data"
			logging.info "Return response"
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
			logging.info "Do same as with 3"
		;;
	esac
}


function network.udp {
  true
}
