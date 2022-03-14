#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.2.7
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1647268068
### CRUCIBLE META DATA ###

require core/.internal
require io/files/dirs/users
require io/files/dirs/group
require io/files/dirs/other

function dirs.rename_dir {
    __verify_nr_args "$#" 2 dirs.rename_dir
    local src target
    src="$1"
    target="$2"
    mv --strip-trailing-slashes --no-target-directory "$src" "$target"
}

function dirs.create_dir {
    __verify_nr_args "$#" 2 dirs.create_dir
    local dir path
    dir="$1"
    path="$2"
    mkdir --parents "$path/$dir"
}

function dirs.create_dir_local {
    __verify_nr_args "$#" 1 dirs.create_dir_local
    local dir 
    dir="$1"
    dirs.create_dir "$dir" ./
}

function dirs.move_dir {
    dirs.rename_dir "$*"
}

function dirs.delete_dir {
    __verify_nr_args "$#" 1 dirs.delete_dir
    local path
    path="$1"
    rm --dir "$path"
}

function dirs.delete_dir_and_files {
    __verify_nr_args "$#" 1 dirs.delete_dir_and_files
    local path
    path="$1"
    rm --recursive "$path"
}

function dirs.copy_dir {
    __verify_nr_args "$#" 2 dirs.copy_dir
    local src target
    src="$1"
    target="$2"
    cp --recursive --strip-trailing-slashes --no-target-directory "$src" "$target"
}

function dirs.dir_exists {
    __verify_nr_args "$#" 1 dirs.dir_exists
    local target result
    if [ -d "$target" ]
    then
        result=1
    else
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function dirs.dir_change_owner_group {
  __verify_nr_args "$#" 3 dirs.dir_change_owner_group
  local target owner group result
  target="$1"
  owner="$2"
  group="$3"
  __sudo chown "$owner:$group" "$target"
}


function dirs.dir_copy_owner {
  __verify_nr_args "$#" 2 dirs.dir_copy_owner
  local target reference
  target="$1"
  reference="$2"
  __sudo chown --reference="$reference" "$target"
}

function dirs.dir_change_owner_group_recursive {
  __verify_nr_args "$#" 3 dirs.dir_change_owner_group_recursive
  local target owner group
  target="$1"
  owner="$2"
  group="$3"
  __sudo chown --recursive "$owner:$group" "$target"
}

function dirs.dir_change_owner {
  __verify_nr_args "$#" 2 dirs.dir_change_owner
  local target owner
  target="$1"
  owner="$2"
  dirs.dir_change_owner_group "$target" "$owner" "$owner"
}

function dirs.dir_change_owner_recursive {
  __verify_nr_args "$#" 2 dirs.dir_change_owner_recursive
  local target owner
  target="$1"
  owner="$2"
  dirs.dir_change_owner_group_recursive "$target" "$owner" "$owner"
}

function dirs.dir_copy_owner_recursive {
  __verify_nr_args "$#" 2 dirs.dir_copy_owner_recursive
  local target reference
  target="$1"
  reference="$2"
  __sudo chown --reference="$reference" --recursive "$target"
}

function dirs.dir_set_perms {
  __verify_nr_args "$#" 2 dirs.dir_set_perms
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

function dirs.dir_set_perms_recursive {
  __verify_nr_args "$#" 2 dirs.dir_set_perms_recursive
  local target perms
  target="$1"
  perms="$2"
  if __verify_arg_is_valid_perm "$perms"
  then
    __sudo chmod --recursive "$perms" "$target"
  else
    logging.error "$perms is invalid perms string"
  fi
}

function dirs.dir_set_all_read_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_all_read_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "ugo=r"
}

function dirs.dir_set_all_read_only {
  __verify_nr_args "$#" 1 dirs.dir_set_all_read_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "ugo+r"
}


function dirs.dir_set_all_write_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_all_write_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "ugo=w"
}

function dirs.dir_set_all_write_only {
  __verify_nr_args "$#" 1 dirs.dir_set_all_write_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "ugo+w"
}

function dirs.dir_set_all_execute_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_all_execute_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "ugo=x"
}

function dirs.dir_set_all_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_set_all_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "ugo+x"
}

function dirs.dir_copy_perms {
  __verify_nr_args "$#" 2 dirs.dir_copy_perms
  local target reference
  target="$1"
  reference="$2"
  __sudo chmod --reference="$reference" "$target"
}

# Recursive


function dirs.dir_set_all_read_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_all_read_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "ugo=r"
}

function dirs.dir_set_all_read_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_all_read_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "ugo+r"
}


function dirs.dir_set_all_write_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_all_write_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "ugo=w"
}

function dirs.dir_set_all_write_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_all_write_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "ugo+w"
}

function dirs.dir_set_all_execute_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_all_execute_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "ugo=x"
}

function dirs.dir_set_all_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_all_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "ugo+x"
}

function dirs.dir_copy_perms_recursive {
  __verify_nr_args "$#" 2 dirs.dir_copy_perms_recursive
  local target reference
  target="$1"
  reference="$2"
  __sudo chmod --reference --reference="$reference" "$target"
}