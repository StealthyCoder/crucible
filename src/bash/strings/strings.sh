#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require arrays/arrays

function strings.to_lowercase {
	__verify_nr_args "$#" 1 strings.to_lowercase
	local string
	string="$1"
	echo "${string,,}"
}

function strings.to_uppercase {
	__verify_nr_args "$#" 1 strings.to_uppercase
	local string
	string="$1"
	echo "${string^^}"
}

function strings.capitalize {
	__verify_nr_args "$#" 1 strings.to_capitalize
	local string
	string="$1"
	echo "${string^}"
}

function strings.replace_char_with {
	__verify_nr_args "$#" 3 strings.replace_char_with
	local string char replacement
	string="$1"
	char="$2"
	replacement="$3"
	echo "${string//$char/$replacement}"
}

function strings.split_by_char {
	__verify_nr_args "$#" 2 strings.split_by_char
	local -a result
	local string char
	result=()
	string="$1"
	char="$2"
	for value in $(strings.replace_char_with "$string" "$char" " "); do
		result+=("$value")
	done
	echo "${result[@]}"
}

function strings.contains_string_sensitive {
	__verify_nr_args "$#" 2 strings.contains_string_sensitive
	local result string search
	string="$1"
	search="$2"
	if [[ "$string" =~ ^.*"$search".*$ ]]; then
		result=1
	else
		result=0
	fi
	__to_boolean "$result" "==" 1
}

function strings.contains_string_ignore_case {
	__verify_nr_args "$#" 2 strings.contains_string_ignore_case
	strings.contains_string_sensitive "$(strings.to_lowercase "$1")" "$(strings.to_lowercase "$1")"
}

function strings.substring {
	__verify_nr_args "$#" 3 strings.substring
	local string from to
	string="$1"
	from="$2"
	to="$3"
	echo "${string:$from:$to}"
}

function strings.length {
	local string
	string="$1"
	echo "${#string}"
}

function strings.lindex {
	__verify_nr_args "$#" 2 strings.lindex
	local string search t
	string="$1"
	search="$2"
	t="${string#*"$search"}"
	echo "$(("$(strings.length "$string")" - "$(strings.length "$t")" - "$(strings.length "$search")"))"
}

function strings.rindex {
	__verify_nr_args "$#" 2 strings.rindex
	local string search t
	string="$1"
	search="$2"
	t="${string##*"$search"}"
	echo "$(("$(strings.length "$string")" - "$(strings.length "$t")" - "$(strings.length "$search")"))"
}

function strings.slice {
	__verify_nr_args "$#" 3 strings.slice
	strings.substring "$1" "$2" "$3"
}

function strings.search_and_replace {
	__verify_nr_args "$#" 3 strings.search_and_replace
	strings.replace_char_with "$1" "$2" "$3"
}

function strings.is_empty {
	local result string
	result=0
	string="$1"
	if [ "$(strings.length "$string")" -eq 0 ]; then
		result=1
	fi
	if [[ "$string" =~ ^[[:space:]]*$ ]]; then
		result=1
	fi
	__to_boolean "$result" "==" 1
}

function strings.concat {
	__verify_nr_args "$#" 2 strings.concat
	echo "$1$2"
}

function strings.equals {
	__verify_nr_args "$#" 2 strings.equals
	local result string
	result=0
	string="$1"
	if [[ "$string" =~ ^"$2"$ ]]; then
		result=1
	fi
	__to_boolean "$result" "==" 1
}

function strings.equals_ignore_case {
	__verify_nr_args "$#" 2 strings.equals_ignore_case
	strings.equals "$(strings.to_lowercase "$1")" "$(strings.to_lowercase "$2")"
}

function strings.join {
	__verify_nr_args "$#" 2 strings.join
	if __verify_if_arg_is_array "$1"; then
		local char result l
		char="$2"
		result=""
		function strings.join._joiner {
			local t
			t="$(strings.concat "$1" "$char")"
			result=$(strings.concat "$result" "$t")
		}
		arrays.foreach "$1" strings.join._joiner
		l="$(strings.length "$result")"
		result="$(strings.slice "$result" 0 $((l - 1)))"
		unset -f strings.join._joiner
		echo "$result"
	fi
}

function strings.starts_with {
	__verify_nr_args "$#" 2 strings.starts_with
	local string char result length
	string="$1"
	char="$2"
	length=$(strings.length "$char")
	result=$(strings.slice "$string" 0 "$length")
	strings.equals "$result" "$char"
}

function strings.ends_with {
	__verify_nr_args "$#" 2 strings.ends_with
	local string char result length total_length
	string="$1"
	char="$2"
	total_length=$(strings.length "$string")
	length=$(strings.length "$char")
	result=$(strings.slice "$string" $((total_length - length)) "$length")
	strings.equals "$result" "$char"
}

function strings.starts_with_ignore_case {
	__verify_nr_args "$#" 2 strings.starts_with_ignore_case
	local string char result length
	string="$1"
	char="$2"
	length=$(strings.length "$char")
	result=$(strings.slice "$string" 0 "$length")
	strings.equals_ignore_case "$result" "$char"
}

function strings.ends_with_ignore_case {
	__verify_nr_args "$#" 2 strings.ends_with_ignore_case
	local string char result length total_length
	string="$1"
	char="$2"
	total_length=$(strings.length "$string")
	length=$(strings.length "$char")
	result=$(strings.slice "$string" $((total_length - length)) "$length")
	strings.equals_ignore_case "$result" "$char"
}
