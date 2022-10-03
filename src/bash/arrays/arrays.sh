#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal

function arrays.transform_into_array {
	local -a arr
	local print
	arr=()
	print="$(declare -p arr | sed -e "s/declare -a arr=/declare -agx $1=/")"
	eval "$print"
	print="$(declare -p arr | sed -e "s/declare -ax arr=/declare -agx $1=/")"
	eval "$print"
}

function arrays.add {
	__verify_nr_args "$#" 2 arrays.add

	if __verify_if_arg_is_array "$1"; then
		local arr element print
		if __check_if_arg_is_local_array "$1"; then
			print="$(declare -p "$1" | sed -e "s/declare -a $1=/arr=/")"
		else
			print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/")"
		fi
		eval "$print"
		element="$2"
		arr+=("$element")
		print="$(declare -p arr | sed -e "s/declare -a arr=/declare -agx $1=/")"
		eval "$print"
	fi

}

function arrays.push {
	arrays.add "$1" "$2"
}

function arrays.add_all {
	if __verify_if_arg_is_array "$1"; then
		local arr element print export_name
		if __check_if_arg_is_local_array "$1"; then
			print="$(declare -p "$1" | sed -e "s/declare -a $1=/arr=/")"
		else
			print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/")"
		fi
		eval "$print"
		export_name="$1"
		shift
		while test $# -gt 0; do
			element="$1"
			arr+=("$element")
			shift
		done
		print="$(declare -p arr | sed -e "s/declare -ax arr=/declare -agx $export_name=/")"
		eval "$print"
	fi
}

function arrays.concat {
	if __verify_if_arg_is_array "$1"; then
		if __verify_if_arg_is_array "$2"; then
			local src target print
			print="$(declare -p "$1" | sed -e "s/declare -ax $1=/src=/")"
			eval "$print"
			print="$(declare -p "$2" | sed -e "s/declare -ax $2=/target=/")"
			eval "$print"
			for element in "${target[@]}"; do
				src+=("$element")
			done
			print="$(declare -p src | sed -e "s/declare -a src=/declare -agx $1=/")"
			eval "$print"
		fi
	fi

}

function arrays.get {
	__verify_nr_args "$#" 2 arrays.get
	if __verify_if_arg_is_array "$1"; then
		local arr element print
		if __check_if_arg_is_local_array "$1"; then
			print="$(declare -p "$1" | sed -e "s/declare -a $1=/arr=/")"
		else
			print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/")"
		fi
		eval "$print"
		echo "${arr[$2]}"
	fi
}

function arrays.pop {
	if __verify_if_arg_is_array "$1"; then
		local arr last element print size counter
		local -a target
		target=()
		if __check_if_arg_is_local_array "$1"; then
			print="$(declare -p "$1" | sed -e "s/declare -a $1=/arr=/")"
		else
			print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/")"
		fi
		eval "$print"
		if [ "${#arr[@]}" -le 0 ]; then
			return 0
		fi

		last="${arr[-1]}"
		size="$((${#arr[@]} - 1))"
		counter=0
		while test "$counter" -ne "$size"; do
			element="${arr[$counter]}"
			target+=("$element")
			counter="$((counter + 1))"
		done

		print="$(declare -p target | sed -e "s/declare -a target=/declare -agx $1=/")"
		eval "$print"

		eval "export $2=$last"
	fi

}

function arrays.values {
	if __verify_if_arg_is_array "$1"; then

		local arr print

		if __check_if_arg_is_local_array "$1"; then
			print="$(declare -p "$1" | sed -e "s/declare -a $1=/arr=/")"
		else
			print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/")"
		fi
		eval "$print"
		echo "${arr[@]}"
	fi
}

function arrays.entries {
	if __verify_if_arg_is_array "$1"; then

		local arr print size counter
		if __check_if_arg_is_local_array "$1"; then
			print="$(declare -p "$1" | sed -e "s/declare -a $1=/arr=/")"
		else
			print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/")"
		fi
		eval "$print"
		if [ "${#arr[@]}" -le 0 ]; then
			return 0
		fi

		size="$((${#arr[@]}))"
		counter=0
		while test "$counter" -ne "$size"; do
			echo "$counter,${arr[$counter]}"
			counter="$((counter + 1))"
		done
	fi

}

function arrays.clear {
	if __verify_if_arg_is_array "$1"; then
		arrays.transform_into_array "$1"
	fi
}

function arrays.map {
	__verify_nr_args "$#" 2 arrays.map
	__verify_arg_is_function "$2"
	if __verify_if_arg_is_array "$1"; then
		local -a arr
		local result print
		arr=()
		for value in $(arrays.values "$1"); do
			result=$("$2" "$value")
			arr+=("$result")
		done
		print="$(declare -p arr | sed -e "s/declare -a arr=/declare -agx $1=/")"
		eval "$print"
	fi
}

function arrays.foreach {
	__verify_nr_args "$#" 2 arrays.foreach
	__verify_arg_is_function "$2"
	if __verify_if_arg_is_array "$1"; then
		for value in $(arrays.values "$1"); do
			"$2" "$value"
		done
	fi
}

function arrays.contains {
	__verify_nr_args "$#" 2 arrays.contains
	if __verify_if_arg_is_array "$1"; then
		local values result
		values="$(arrays.values "$1")"
		if [ "$(echo "$values" | grep -c "$2")" -ge 1 ]; then
			result=1
		else
			result=0
		fi
		__to_boolean "$result" "==" 1
	fi
}
