#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require strings/strings
require arrays/arrays
require io/files/safe
require io/binary/safe

function search.find_files_by_filename {
	__verify_nr_args "$#" 2 search.find_file_by_filename
	local location token
	location="$1"
	token="$2"

	arrays.transform_into_array names

	function search._recursive_find_files {
		local augmented
		for f in $(strings.split_by_char "$(files.list_dir_recursive "$location")" "\n"); do
			augmented=$(strings.replace_char_with "$f" ":" "/")
			if [ -f "$augmented" ]; then
				if strings.contains_string_sensitive "$augmented" "$token"; then
					if strings.starts_with "$augmented" "$location/"; then
						arrays.add names "$augmented"
					fi
				fi
			fi
		done
	}

	search._recursive_find_files "$location" "$token"
	arrays.foreach names echo
	unset names
	unset -f search._recursive_find_files
}

function search.find_files_by_filename_ignore_case {
	__verify_nr_args "$#" 2 search.find_file_by_filename_insensitive
	local location token
	location="$1"
	token="$2"

	arrays.transform_into_array names

	function search._recursive_find_files {
		local augmented
		for f in $(strings.split_by_char "$(files.list_dir_recursive "$location")" "\n"); do
			augmented=$(strings.replace_char_with "$f" ":" "/")
			if [ -f "$augmented" ]; then
				if strings.strings.contains_string_ignore_case "$augmented" "$token"; then
					if strings.starts_with "$augmented" "$location/"; then
						arrays.add names "$augmented"
					fi
				fi
			fi
		done
	}

	search._recursive_find_files "$location" "$token"
	arrays.foreach names echo
	unset names
	unset -f search._recursive_find_files
}

function search.find_files_containing {
	__verify_nr_args "$#" 2 search.find_file_containing
	local location token
	location="$1"
	token="$2"

	arrays.transform_into_array names

	function search._recursive_find_files {
		local augmented
		for f in $(strings.split_by_char "$(files.list_dir_recursive "$location")" "\n"); do
			augmented=$(strings.replace_char_with "$f" ":" "/")
			if [ -f "$augmented" ]; then
				local result
				result="$(binary.read_file "$augmented")"
				if [ -z "$result" ]; then
					result="$(binary.extract_strings "$augmented")"
				fi
				if strings.contains_string_sensitive "$result" "$token"; then
					if strings.starts_with "$augmented" "$location/"; then
						arrays.add names "$augmented"
					fi
				fi
			fi
		done
	}

	search._recursive_find_files "$location" "$token"
	arrays.foreach names echo
	unset names
	unset -f search._recursive_find_files
}

function search.find_files_containing_ignore_case {
	__verify_nr_args "$#" 2 search.find_file_containing
	local location token
	location="$1"
	token="$2"

	arrays.transform_into_array names

	function search._recursive_find_files {
		local augmented
		for f in $(strings.split_by_char "$(files.list_dir_recursive "$location")" "\n"); do
			augmented=$(strings.replace_char_with "$f" ":" "/")
			if [ -f "$augmented" ]; then
				local result
				result="$(binary.read_file "$augmented")"
				if [ -z "$result" ]; then
					result="$(binary.extract_strings "$augmented")"
				fi
				if strings.contains_string_ignore_case "$result" "$token"; then
					if strings.starts_with "$augmented" "$location/"; then
						arrays.add names "$augmented"
					fi
				fi
			fi
		done
	}

	search._recursive_find_files "$location" "$token"
	arrays.foreach names echo
	unset names
	unset -f search._recursive_find_files
}

function search.find_files_by_extension {
	__verify_nr_args "$#" 2 search.find_file_by_filename
	local location token
	location="$1"
	token="$2"

	arrays.transform_into_array names

	function search._recursive_find_files {
		local augmented
		for f in $(strings.split_by_char "$(files.list_dir_recursive "$location")" "\n"); do
			augmented=$(strings.replace_char_with "$f" ":" "/")
			if [ -f "$augmented" ]; then
				if strings.ends_with "$augmented" "$token"; then
					if strings.starts_with "$augmented" "$location/"; then
						arrays.add names "$augmented"
					fi
				fi
			fi
		done
	}

	search._recursive_find_files "$location" "*$token"
	arrays.foreach names echo
	unset names
	unset -f search._recursive_find_files
}

function search.find_files_by_extension_ignore_case {
	__verify_nr_args "$#" 2 search.find_file_by_filename
	local location token
	location="$1"
	token="$2"

	arrays.transform_into_array names

	function search._recursive_find_files {
		local augmented
		for f in $(strings.split_by_char "$(files.list_dir_recursive "$location")" "\n"); do
			augmented=$(strings.replace_char_with "$f" ":" "/")
			if [ -f "$augmented" ]; then
				if strings.ends_with_ignore_case "$augmented" "$token"; then
					if strings.starts_with_ignore_case "$augmented" "$location/"; then
						arrays.add names "$augmented"
					fi
				fi
			fi
		done
	}

	search._recursive_find_files "$location" "*$token"
	arrays.foreach names echo
	unset names
	unset -f search._recursive_find_files
}
