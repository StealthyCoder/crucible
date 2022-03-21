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

function search.find_file_by_filename {
    __verify_nr_args "$#" 2 search.find_file_by_filename
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

function search.find_file_by_filename_insensitive {
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
            elif strings.contains_string_insensitive "$f" "$token"
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

function search.find_file_containing {
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
            then
                local result
                result="$(binary.read_file "$loc/$f")"
                if [ -z "$result" ]
                then
                    result="$(binary.extract_strings "$loc/$f")"
                fi
                strings.contains_string_sensitive "$result" "$token"
                arrays.add names "$loc/$f"
            fi
        done
    }

    search._recursive_find_files "$location" "$token"
    arrays.foreach names echo
    unset names
    unset -f search._recursive_find_files
}

# function search.find_file_containing {
# 	__verify_nr_args "$#" 2 search.find_in_file
# 	local location token
# 	location="$1"
# 	token="$2"
# 	if __command_exists "find"
#     then
#         find 
#     else
#         # Search implementation here using strings
#     fi
# }

# function search.file_contains {
#     __verify_nr_args "$#" 2 search.find_in_file
# 	local file token
# 	file="$1"
# 	token="$2"
# 	if __command_exists "find"
#     then
#         find 
#     else
#         # Search implementation here using strings
#     fi
# }

# function search.find_all_files_containing {
# 	__verify_nr_args "$#" 1 redirect.to_file_void
# 	local execute
# 	execute="$1"
# 	redirect.to_file "$execute" /dev/null
# }

# function search.find_files_containing {
# 	__verify_nr_args "$#" 1 redirect.merge_all
# 	local execute
# 	execute="$1"
# 	$execute 2>&1
# }


# Search
#   v Find specific files with filename containing keyword sensitive
#   v Find specific files with filename containing keyword insensitive
#   - Find specific file containing keyword
#   - Find specific files containing keyword
#   - Find if file contains keyword
#   - Find in all files from directory down
#   - Fallback to search with strings. module
#   - 