#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.3.0
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1791901074
### CRUCIBLE META DATA ###

require logging/logging

function __verify_nr_args {
	if [ "$#" -ne 3 ]; then
		logging.info "Must pass three arguments to this function."
		logging.info " 1. Number of arguments gotten"
		logging.info " 2. Number of arguments expected"
		logging.info " 3. Name of the function"
		logging.info " Example: __verify_nr_args 1 1 arrays.dummy"
		exit 1
	fi
	if [ "$1" -gt "$2" ]; then
		logging.warning "Need exactly $2 arguments for $3, gotten $1."
		logging.warning "The surplus will not be used."
	elif [ "$1" -ne "$2" ]; then
		logging.error "Need exactly $2 arguments for $3, gotten $1."
		exit 1
	fi
}

function __get_operator {
	__verify_nr_args "$#" 1 __get_operator
	local -A operators
	operators=()

	operators+=(["<"]="-lt")
	operators+=(["<="]="-le")
	operators+=([">"]="-gt")
	operators+=([">="]="-ge")
	operators+=(["=="]="-eq")
	operators+=(["!="]="-ne")
	if [ ! "${operators[$1]+_}" ]; then
		logging.error "Argument needs to be >,>=,<,<=,==,!= was $1"
	fi
	echo "${operators[$1]}"
}

function __to_boolean {
	__verify_nr_args "$#" 3 __to_boolean
	local operator result
	operator=$(__get_operator "$2")
	result=0
	if [ "$operator" == "-lt" ]; then
		result=$(if [[ "$1" -lt "$3" ]]; then echo 1; else echo 0; fi)
	elif [ "$operator" == "-le" ]; then
		result=$(if [[ "$1" -le "$3" ]]; then echo 1; else echo 0; fi)
	elif [ "$operator" == "-gt" ]; then
		result=$(if [[ "$1" -gt "$3" ]]; then echo 1; else echo 0; fi)
	elif [ "$operator" == "-ge" ]; then
		result=$(if [[ "$1" -ge "$3" ]]; then echo 1; else echo 0; fi)
	elif [ "$operator" == "-eq" ]; then
		result=$(if [[ "$1" -eq "$3" ]]; then echo 1; else echo 0; fi)
	elif [ "$operator" == "-ne" ]; then
		result=$(if [[ "$1" -ne "$3" ]]; then echo 1; else echo 0; fi)
	fi

	if [[ "$result" -eq 1 ]]; then
		true
	else
		false
	fi
}

function __verify_if_arg_is_array {
	local result
	result=1
	if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -ax\ "$1"= ]]; then
		if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -a\ "$1" ]]; then
			logging.error "Argument needs to be an array created by arrays.transform_into_array"
			logging.error "$(declare -p "$1")"
			result=0
		fi
	fi
	__to_boolean "$result" "==" 1
}

function __check_if_arg_is_local_array {
	local result
	result=1
	if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -a\ "$1" ]]; then
		result=0
	fi
	__to_boolean "$result" "==" 1
}

function __verify_arg_is_function {
	local result
	result=1
	if [ "$(typeset -f | grep -c "$1 ()")" -eq 0 ]; then
		result=0
	fi
	__to_boolean "$result" "==" 1
}

function __verify_if_arg_is_map {
	local result
	result=1
	if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -Ax\ "$1"= ]]; then
		if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -A\ "$1" ]]; then
			logging.error "Argument needs to be a map created by maps.transform_into_map"
			logging.error "$(declare -p "$1")"
			result=0
		fi
	fi
	__to_boolean "$result" "==" 1
}

function __check_if_arg_is_local_map {
	local result
	result=1
	if [[ ! "$(declare -p "$1" 2>/dev/null)" =~ ^declare\ -A\ "$1" ]]; then
		result=0
	fi
	__to_boolean "$result" "==" 1
}

function __verify_arg_is_valid_perm {
	local result
	result=1
	if [[ ! "$1" =~ [ugoa]*([-+=]([rwxXst]*|[ugo]))+|[-+=][0-7]+ ]]; then
		result=0
	fi
	if [[ "$1" =~ [0-7]{4} ]]; then
		result=1
	fi
	__to_boolean "$result" "==" 1
}

function __is_root {
	local result
	if [ "$EUID" -eq 0 ]; then
		result=1
	else
		result=0
	fi
	__to_boolean "$result" "==" 1
}

function __sudo {
	local sudo_result doas_result
	command -v sudo >/dev/null 2>&1
	sudo_result=$?
	command -v doas >/dev/null 2>&1
	doas_result=$?
	if __to_boolean "$sudo_result" "==" 0; then
		sudo "$@"
	elif __to_boolean "$doas_result" "==" 0; then
		doas "$@"
	elif __is_root; then
		"$@"
	else
		local args
		args=""
		logging.error "No sudo or doas installed, cannot run this command:"
		for i in "$@"; do
			args+="$i "
		done
		logging.error "$args"
	fi
}

function __command_exists {
	local command_result
	command -v "$1" >/dev/null 2>&1
	command_result=$?
	__to_boolean "$command_result" "==" 0
}

function __ask {
	read -r -p "$1" var
	echo "$var"
}

# Reads bytes from a stream with nothing but bash and leaves them as upper case
# hexadecimal digits in __READ_HEX. Bash variables cannot hold a NUL byte, so
# the stream is read in pieces that end at a NUL; every piece that was ended by
# a NUL is followed by 00, which keeps the result byte exact.
#
# A read never asks for more than what is left to read (read -n), so nothing is
# taken from the stream beyond <count> bytes. That makes it safe for a protocol
# with a length in front (two bytes, then the message) and for a file: the first
# bytes of a large one are read and not the whole of it.
# Usage: __read_bytes_hex <fd> <count> [timeout in seconds, 0 is none]
# Fails, with what did arrive in __READ_HEX, when the stream ends or the timeout passes.
declare -g __READ_HEX
function __read_bytes_hex {
	local LC_ALL=C
	local fd count timeout_seconds out have piece status i char
	local -a timeout_args
	fd="$1"
	count="$2"
	timeout_seconds="${3:-0}"
	timeout_args=()
	if [[ "$timeout_seconds" != "0" ]]; then
		timeout_args=(-t "$timeout_seconds")
	fi
	out=""
	have=0
	while [ "$have" -lt "$count" ]; do
		IFS= read -r -d '' -n $((count - have)) "${timeout_args[@]}" -u "$fd" piece
		status=$?
		for ((i = 0; i < ${#piece}; i++)); do
			printf -v char '%02X' "'${piece:i:1}"
			out+="$char"
		done
		have=$((have + ${#piece}))
		if [ "$status" -ne 0 ]; then
			break
		fi
		# Reading stopped at a NUL, unless the piece was as long as was asked for
		if [ "$have" -lt "$count" ]; then
			out+="00"
			have=$((have + 1))
		fi
	done
	__READ_HEX="$out"
	[ "$have" -ge "$count" ]
}
