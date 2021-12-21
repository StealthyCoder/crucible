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

function files.delete_file {
    __verify_nr_args "$#" 1 files.delete_file
    local path
    path="$1"
    if [ -f "$path" ]
    then
        rm -i "$path"
    fi
}

function files.delete_dir {
    __verify_nr_args "$#" 1 files.delete_dir
    local path
    path="$1"
    if [ -d "$path" ]
    then
        rm -di "$path"
    fi
}

function files.delete_dir_and_files {
    __verify_nr_args "$#" 1 files.delete_dir_and_files
    local path
    path="$1"
    if [ -f "$path" ]
    then
        files.delete_file "$path"
    elif [ -d "$path" ]
    then
        if [ "$path" != "/" ]
        then
            rm -ri "$path"
        fi
    fi
}

function files.copy_file {
    __verify_nr_args "$#" 2 files.copy_file
    local src target
    src="$1"
    target="$2"
    if [ -f "$src" ]
    then
        cp --strip-trailing-slashes --no-target-directory --no-clobber "$src" "$target"
    fi
}

function files.copy_dir {
    __verify_nr_args "$#" 2 files.copy_dir
    local src target
    src="$1"
    target="$2"
    if [ -d "$src" ]
    then
        cp --recursive --strip-trailing-slashes --no-target-directory --no-clobber "$src" "$target"
    fi
}

function files.update_file {
    __verify_nr_args "$#" 2 files.update_file
    local src target
    src="$1"
    target="$2"
    if [ ! -f "$target" ]
    then
        cp --update --strip-trailing-slashes --no-target-directory --no-clobber "$src" "$target"
    fi
}

function files.create_file {
    __verify_nr_args "$#" 1 files.create_file
    local target
    target="$1"
    if [ ! -f "$target" ]
    then
        touch "$target"
    fi
}