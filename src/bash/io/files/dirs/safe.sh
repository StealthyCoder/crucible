#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.2.7
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1647268068
### CRUCIBLE META DATA ###

require io/files/dirs

function dirs.rename_dir {
    __verify_nr_args "$#" 2 dirs.rename_dir
    local src target
    src="$1"
    target="$2"
    if [ -d "$src" ]
    then
        mv -n -T "$src" "$target"
    fi
}

function dirs.move_dir {
    dirs.rename_dir "$*"
}

function dirs.delete_dir {
    __verify_nr_args "$#" 1 dirs.delete_dir
    local path
    path="$1"
    if [ -d "$path" ]
    then
        rm -di "$path"
    fi
}

function dirs.delete_dir_and_files {
    __verify_nr_args "$#" 1 dirs.delete_dir_and_files
    local path
    path="$1"
    if [ -f "$path" ]
    then
        rm -i "$path"
    elif [ -d "$path" ]
    then
        if [ "$path" != "/" ]
        then
            dirs.delete_dir "$path"
        fi
    fi
}

function dirs.copy_dir {
    __verify_nr_args "$#" 2 dirs.copy_dir
    local src target
    src="$1"
    target="$2"
    if [ -d "$src" ]
    then
        cp --recursive --strip-trailing-slashes --no-target-directory --no-clobber "$src" "$target"
    fi
}

function dirs.dir_change_owner_group {
  __verify_nr_args "$#" 3 dirs.dir_change_owner_group
  local target owner group
  target="$1"
  owner="$2"
  group="$3"
  if [ -d "$target" ]
  then
    __sudo chown "$owner:$group" "$target"
  fi
}

function dirs.dir_change_owner_group_recursive {
  __verify_nr_args "$#" 3 dirs.dir_change_owner_group
  local target owner group
  target="$1"
  owner="$2"
  group="$3"
  if [ -d "$target" ]
  then
    __sudo chown --recursive "$owner:$group" "$target"
  fi
}

function dirs.dir_change_owner {
  __verify_nr_args "$#" 2 dirs.dir_change_owner
  local target owner
  target="$1"
  owner="$2"
  dirs.dir_change_owner_group "$target" "$owner" "$owner"
}

function dirs.dir_copy_owner {
  __verify_nr_args "$#" 2 dirs.dir_copy_owner
  local target reference
  target="$1"
  reference="$2"
  if [ -d "$target" ]
  then
    __sudo chown --reference="$reference" "$target"
  fi
}

function dirs.dir_copy_owner_recursive {
  __verify_nr_args "$#" 2 dirs.dir_copy_owner
  local target reference
  target="$1"
  reference="$2"
  if [ -d "$target" ]
  then
    __sudo chown --reference="$reference" --recursive "$target"
  fi
}

function dirs.dir_set_perms {
  __verify_nr_args "$#" 2 dirs.dir_set_perms
  local target perms
  target="$1"
  perms="$2"
  if __verify_arg_is_valid_perm "$perms"
  then
    if [ -d "$target" ]
    then
        if [ "$(__check_log_level "DEBUG")" -ne 0 ]
        then
          __sudo chmod "$perms" "$target" --verbose
        else
          __sudo chmod "$perms" "$target" --changes
        fi
    fi
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
    if [ -d "$target" ]
    then
        if [ "$(__check_log_level "DEBUG")" -ne 0 ]
        then
          __sudo chmod "$perms" "$target" --verbose --recursive
        else
          __sudo chmod "$perms" "$target" --changes --recursive
        fi
    fi
  else
    logging.error "$perms is invalid perms string"
  fi
}