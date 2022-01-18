#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require io/files/users
require io/files/group
require io/files/other

function files.rename_file {
    __verify_nr_args "$#" 2 files.rename_file
    local src target
    src="$1"
    target="$2"
    mv --strip-trailing-slashes --no-target-directory "$src" "$target"
}

function files.rename_dir {
    __verify_nr_args "$#" 2 files.rename_dir
    files.rename_file $*
}

function files.create_dir {
    __verify_nr_args "$#" 2 files.create_dir
    local dir path
    dir="$1"
    path="$2"
    mkdir --parents "$path/$dir"
}

function files.create_dir_local {
    __verify_nr_args "$#" 1 files.create_dir_local
    local dir 
    dir="$1"
    files.create_dir "$dir" ./
}

function files.change_dir {
    __verify_nr_args "$#" 1 files.change_dir
    local path
    path="$1"
    pushd "$path" > /dev/null
}

function files.change_dir_unwind {
    popd &> /dev/null
}

function files.change_dir_add_stack {
    __verify_nr_args "$#" 1 files.change_dir
    local path
    path="$1"
    pushd -n "$path" > /dev/null
}

function files.change_dir_history {
    dirs
}

function files.change_dir_history_clear {
    dirs -c
}

function files.list_dir_detailed {
    __verify_nr_args "$#" 1 files.list_dir_detailed
    local path
    path="$1"
    ls --all -l --human-readable "$path"
}

function files.list_current_dir_detailed {
    files.list_dir_detailed ./
}

function files.list_dir_hidden {
    __verify_nr_args "$#" 1 files.list_dir_hidden
    local path
    path="$1"
    ls --almost-all "$path"
}

function files.list_current_dir_hidden {
    files.list_dir_hidden ./
}

function files.list_dir {
    __verify_nr_args "$#" 1 files.list_dir
    local path
    path="$1"
    ls "$path"
}

function files.list_current_dir {
    files.list_dir ./
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
    rm "$path"
}

function files.delete_dir {
    __verify_nr_args "$#" 1 files.delete_dir
    local path
    path="$1"
    rm --dir "$path"
}

function files.delete_dir_and_files {
    __verify_nr_args "$#" 1 files.delete_dir_and_files
    local path
    path="$1"
    rm --recursive "$path"
}

function files.copy_file {
    __verify_nr_args "$#" 2 files.copy_file
    local src target
    src="$1"
    target="$2"
    cp --strip-trailing-slashes --no-target-directory "$src" "$target"
}

function files.copy_dir {
    __verify_nr_args "$#" 2 files.copy_dir
    local src target
    src="$1"
    target="$2"
    cp --recursive --strip-trailing-slashes --no-target-directory "$src" "$target"
}

function files.update_file {
    __verify_nr_args "$#" 2 files.update_file
    local src target
    src="$1"
    target="$2"
    cp --update --strip-trailing-slashes --no-target-directory "$src" "$target"
}

function files.create_file {
    __verify_nr_args "$#" 1 files.create_file
    local target
    target="$1"
    touch "$target"
}

function files.file_exists {
    __verify_nr_args "$#" 1 files.file_exists
    local target result
    if [ -f "$target" ]
    then
        result=1
    else
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function files.dir_exists {
    __verify_nr_args "$#" 1 files.dir_exists
    local target result
    if [ -d "$target" ]
    then
        result=1
    else
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function files.file_change_owner_group {
  __verify_nr_args "$#" 3 files.file_change_owner_group
  local target owner group result
  target="$1"
  owner="$2"
  group="$3"
  __sudo chown "$owner:$group" "$target"
}


function files.file_change_owner {
  __verify_nr_args "$#" 2 files.file_change_owner
  local target owner
  target="$1"
  owner="$2"
  files.file_change_owner_group "$target" "$owner" "$owner"
}

function files.file_copy_owner {
  __verify_nr_args "$#" 2 files.file_copy_owner
  local target reference
  target="$1"
  reference="$2"
  __sudo chown --reference="$reference" "$target"
}

function files.dir_change_owner_group {
  __verify_nr_args "$#" 3 files.dir_change_owner_group
  local target owner group
  target="$1"
  owner="$2"
  group="$3"
  files.file_change_owner_group $target $owner $group
}

function files.dir_change_owner_group_recursive {
  __verify_nr_args "$#" 3 files.dir_change_owner_group_recursive
  local target owner group
  target="$1"
  owner="$2"
  group="$3"
  __sudo chown --recursive "$owner:$group" "$target"
}

function files.dir_change_owner {
  __verify_nr_args "$#" 2 files.dir_change_owner
  local target owner
  target="$1"
  owner="$2"
  files.dir_change_owner_group "$target" "$owner" "$owner"
}

function files.dir_change_owner_recursive {
  __verify_nr_args "$#" 2 files.dir_change_owner
  local target owner
  target="$1"
  owner="$2"
  files.dir_change_owner_group_recursive "$target" "$owner" "$owner"
}

function files.dir_copy_owner {
  __verify_nr_args "$#" 2 files.dir_copy_owner
  local target reference
  target="$1"
  reference="$2"
  files.file_copy_owner "$target" "$reference"
}

function files.dir_copy_owner_recursive {
  __verify_nr_args "$#" 2 files.dir_copy_owner
  local target reference
  target="$1"
  reference="$2"
  __sudo chown --reference="$reference" --recursive "$target"
}

function files.file_set_perms {
  __verify_nr_args "$#" 2 files.file_set_perms
  local target perms
  target="$1"
  perms="$2"
  if __verify_arg_is_valid_perm "$perms"
  then
    __sudo chmod "$perms" "$target"
  else
    logging.error "$perms is invalid perms string"
  fi
}

function files.file_set_all_read_only_clear {
  __verify_nr_args "$#" 1 files.file_set_all_read_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "ugo=r"
}

function files.file_set_all_read_only {
  __verify_nr_args "$#" 1 files.file_set_all_read_only
  local target
  target="$1"
  files.file_set_all_read_only_clear "$target"
}


function files.file_set_all_write_only_clear {
  __verify_nr_args "$#" 1 files.file_set_all_write_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "ugo=w"
}

function files.file_set_all_write_only {
  __verify_nr_args "$#" 1 files.file_set_all_write_only
  local target
  target="$1"
  files.file_set_all_write_only_clear "$target"
}

function files.file_set_all_execute_only_clear {
  __verify_nr_args "$#" 1 files.file_set_all_execute_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "ugo=x"
}

function files.file_set_all_execute_only {
  __verify_nr_args "$#" 1 files.file_set_all_execute_only_clear
  local target
  target="$1"
  files.file_set_all_execute_only_clear "$target"
}

function files.file_copy_perms {
  __verify_nr_args "$#" 2 files.file_copy_perms
  local target reference
  target="$1"
  reference="$2"
  __sudo chmod --reference="$reference" "$target"
}


# file perms
#   file perms for dir
#       with and without recursive
##
