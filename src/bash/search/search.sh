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
        local loc
        loc="$1"
        for f in "$(files.list_dir "$loc")"
        do
            if [ -d "$f" ]
            then
                search._recursive_find_files "$loc/$f" "$token"
            elif strings.contains_string_sensitive "$f" "$token"
            then
                arrays.add names "$loc/$f"
            fi
        done
    }

    search._recursive_find_files "$location" "$token"
    arrays.foreach names echo
    unset names
    unset -f search._recursive_find_files
}

function search.find_files_by_filename_insensitive {
    __verify_nr_args "$#" 2 search.find_file_by_filename_insensitive
	local location token
	location="$1"
	token="$2"
	
    arrays.transform_into_array names

    function search._recursive_find_files {
        local loc
        loc="$1"
        for f in $(files.list_dir "$loc")
        do
            if [ -d "$f" ]
            then
                search._recursive_find_files "$loc/$f" "$token"
            elif strings.strings.contains_string_ignore_case "$f" "$token"
            then
                arrays.add names "$loc/$f"
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
        local loc
        loc="$1"
        for f in $(files.list_dir "$loc")
        do
            if [ -d "$f" ]
            then
                search._recursive_find_files "$loc/$f" "$token"
            else
                local result
                result="$(binary.read_file "$loc/$f")"
                if [ -z "$result" ]
                then
                    result="$(binary.extract_strings "$loc/$f")"
                fi
                if strings.contains_string_sensitive "$result" "$token"
                then
                    arrays.add names "$loc/$f"
                fi
            fi
        done
    }

    search._recursive_find_files "$location" "$token"
    arrays.foreach names echo
    unset names
    unset -f search._recursive_find_files
}

function search.find_files_containing_insensitive {
    __verify_nr_args "$#" 2 search.find_file_containing
	local location token
	location="$1"
	token="$2"
	
    arrays.transform_into_array names

    function search._recursive_find_files {
        local loc
        loc="$1"
        for f in $(files.list_dir "$loc")
        do
            if [ -d "$f" ]
            then
                search._recursive_find_files "$loc/$f" "$token"
            else
                local result
                result="$(binary.read_file "$loc/$f")"
                if [ -z "$result" ]
                then
                    result="$(binary.extract_strings "$loc/$f")"
                fi
                if strings.contains_string_ignore_case "$result" "$token"
                then
                    arrays.add names "$loc/$f"
                fi
            fi
        done
    }

    search._recursive_find_files "$location" "$token"
    arrays.foreach names echo
    unset names
    unset -f search._recursive_find_files
}