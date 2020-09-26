#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require io/files/files

function files.rename_file {
    __verify_nr_args "$#" 2 files.rename_file
    local src target
    src="$1"
    target="$2"
    if [ -f "$src" ]
    then
        mv -n -T "$src" "$target"
    fi
}

function files.rename_dir {
    __verify_nr_args "$#" 2 files.rename_dir
    local src target
    src="$1"
    target="$2"
    if [ -d "$src" ]
    then
        mv -n -T "$src" "$target"
    fi
}

function files.move_file {
    files.rename_file $*
}

function files.move_dir {
    files.rename_dir $*
}