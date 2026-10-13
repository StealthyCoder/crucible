#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging
require strings/strings
require io/binary/safe

# Prints every file below the location that satisfies the predicate, in the
# order of the shell's globbing. The predicate is called with the path of the
# file and the token.
function search._find_files {
	local location predicate token file restore
	location="${1%/}"
	predicate="$2"
	token="$3"
	if [ ! -d "$location" ]; then
		logging.error "$location is not a directory"
		return 1
	fi
	restore="$(shopt -p globstar dotglob nullglob)"
	shopt -s globstar dotglob nullglob
	for file in "$location"/**; do
		if [ -f "$file" ] && "$predicate" "$file" "$token"; then
			echo "$file"
		fi
	done
	eval "$restore"
}

function search._name_contains {
	strings.contains_string_sensitive "${1##*/}" "$2"
}

function search._name_contains_ignore_case {
	strings.contains_string_ignore_case "${1##*/}" "$2"
}

function search._name_ends_with {
	strings.ends_with "${1##*/}" "$2"
}

function search._name_ends_with_ignore_case {
	strings.ends_with_ignore_case "${1##*/}" "$2"
}

function search._content {
	local content
	content="$(binary.read_file "$1")"
	if [ -z "$content" ]; then
		content="$(binary.extract_strings "$1" 2>/dev/null)"
	fi
	echo "$content"
}

function search._content_contains {
	strings.contains_string_sensitive "$(search._content "$1")" "$2"
}

function search._content_contains_ignore_case {
	strings.contains_string_ignore_case "$(search._content "$1")" "$2"
}

function search.find_files_by_filename {
	__verify_nr_args "$#" 2 search.find_files_by_filename
	search._find_files "$1" search._name_contains "$2"
}

function search.find_files_by_filename_ignore_case {
	__verify_nr_args "$#" 2 search.find_files_by_filename_ignore_case
	search._find_files "$1" search._name_contains_ignore_case "$2"
}

function search.find_files_containing {
	__verify_nr_args "$#" 2 search.find_files_containing
	search._find_files "$1" search._content_contains "$2"
}

function search.find_files_containing_ignore_case {
	__verify_nr_args "$#" 2 search.find_files_containing_ignore_case
	search._find_files "$1" search._content_contains_ignore_case "$2"
}

function search.find_files_by_extension {
	__verify_nr_args "$#" 2 search.find_files_by_extension
	search._find_files "$1" search._name_ends_with "$2"
}

function search.find_files_by_extension_ignore_case {
	__verify_nr_args "$#" 2 search.find_files_by_extension_ignore_case
	search._find_files "$1" search._name_ends_with_ignore_case "$2"
}
