#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require io/files/files
require io/files/safe/users
require io/files/safe/group
require io/files/safe/other

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

function files.file_change_owner_group {
  __verify_nr_args "$#" 3 files.file_change_owner_group
  local target owner group result
  target="$1"
  owner="$2"
  group="$3"
  if [ -f "$target" ]
  then
    __sudo chown "$owner:$group" "$target"
  fi
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
  if [ -f "$target" ]
  then
    __sudo chown --reference="$reference" "$target"
  fi
}

function files.dir_change_owner_group {
  __verify_nr_args "$#" 3 files.dir_change_owner_group
  local target owner group
  target="$1"
  owner="$2"
  group="$3"
  if [ -d "$target" ]
  then
    __sudo chown "$owner:$group" "$target"
  fi
}

function files.dir_change_owner_group_recursive {
  __verify_nr_args "$#" 3 files.dir_change_owner_group
  local target owner group
  target="$1"
  owner="$2"
  group="$3"
  if [ -d "$target" ]
  then
    __sudo chown --recursive "$owner:$group" "$target"
  fi
}

function files.dir_change_owner {
  __verify_nr_args "$#" 2 files.dir_change_owner
  local target owner
  target="$1"
  owner="$2"
  files.dir_change_owner_group "$target" "$owner" "$owner"
}

function files.dir_copy_owner {
  __verify_nr_args "$#" 2 files.dir_copy_owner
  local target reference
  target="$1"
  reference="$2"
  if [ -d "$target" ]
  then
    __sudo chown --reference="$reference" "$target"
  fi
}

function files.dir_copy_owner_recursive {
  __verify_nr_args "$#" 2 files.dir_copy_owner
  local target reference
  target="$1"
  reference="$2"
  if [ -d "$target" ]
  then
    __sudo chown --reference="$reference" --recursive "$target"
  fi
}

function files.file_set_perms {
  __verify_nr_args "$#" 2 files.file_set_perms
  local target perms
  target="$1"
  perms="$2"
  if __verify_arg_is_valid_perm "$perms"
  then
    if [ -f "$target" ]
    then
        __sudo chmod "$perms" "$target"
    fi
  else
    logging.error "$perms is invalid perms string"
  fi
}