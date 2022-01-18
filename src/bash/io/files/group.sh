#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require io/files/files

function files.file_set_group_read_only_clear {
  __verify_nr_args "$#" 1 files.file_set_group_read_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "g=r,ug-rxw"
}

function files.file_set_group_read_only {
  __verify_nr_args "$#" 1 files.file_set_group_read_only
  local target
  target="$1"
  files.file_set_perms "$target" "g=r"
}

function files.file_set_user_group_read_only_clear {
  __verify_nr_args "$#" 1 files.file_set_user_group_read_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "ug=r,o-rxw"
}

function files.file_set_user_group_read_only{
  __verify_nr_args "$#" 1 files.file_set_user_group_read_only
  local target
  target="$1"
  files.file_set_perms "$target" "ug=r"
}

function files.file_set_group_other_read_only_clear {
  __verify_nr_args "$#" 1 files.file_set_group_other_read_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "go=r,u-rxw"
}

function files.file_set_group_other_read_only {
  __verify_nr_args "$#" 1 files.file_set_group_other_read_only
  local target
  target="$1"
  files.file_set_perms "$target" "go=r"
}

function files.file_set_group_write_only_clear {
  __verify_nr_args "$#" 1 files.file_set_group_write_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "g=w,ug-rxw"
}

function files.file_set_group_write_only {
  __verify_nr_args "$#" 1 files.file_set_group_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "g=w"
}

function files.file_set_user_group_write_only_clear {
  __verify_nr_args "$#" 1 files.file_set_user_group_write_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "ug=w,o-rxw"
}


function files.file_set_user_group_write_only {
  __verify_nr_args "$#" 1 files.file_set_user_group_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "ug=w"
}

function files.file_set_group_other_write_only_clear {
  __verify_nr_args "$#" 1 files.file_set_group_other_write_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "go=w,u-rxw"
}

function files.file_set_group_other_write_only {
  __verify_nr_args "$#" 1 files.file_set_group_other_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "go=w"
}

function files.file_set_group_execute_only_clear {
  __verify_nr_args "$#" 1 files.file_set_group_execute_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "g=x,ug-rxw"
}

function files.file_set_group_execute_only {
  __verify_nr_args "$#" 1 files.file_set_group_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "g=x"
}

function files.file_set_user_group_execute_only_clear {
  __verify_nr_args "$#" 1 files.file_set_user_group_execute_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "ug=x,o-rxw"
}

function files.file_set_user_group_execute_only {
  __verify_nr_args "$#" 1 files.file_set_user_group_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "ug=x"
}

function files.file_set_group_other_execute_only_clear {
  __verify_nr_args "$#" 1 files.file_set_group_other_execute_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "go=x,u-rxw"
}

function files.file_set_group_other_execute_only {
  __verify_nr_args "$#" 1 files.file_set_group_other_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "go=x"
}

function files.file_add_group_read_only {
  __verify_nr_args "$#" 1 files.file_add_group_read_only
  local target
  target="$1"
  files.file_set_perms "$target" "g+r"
}

function files.file_add_group_write_only {
  __verify_nr_args "$#" 1 files.file_add_group_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "g+w"
}

function files.file_add_group_execute_only {
  __verify_nr_args "$#" 1 files.file_add_group_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "g+x"
}

function files.file_add_group_read_write_only {
  __verify_nr_args "$#" 1 files.file_add_group_read_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "g+rw"
}

function files.file_add_group_read_execute_only {
  __verify_nr_args "$#" 1 files.file_add_group_read_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "g+rx"
}

function files.file_add_group_write_execute_only {
  __verify_nr_args "$#" 1 files.file_add_group_write_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "g+wx"
}

function files.file_add_group_read_write_execute_only {
  __verify_nr_args "$#" 1 files.file_add_group_read_write_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "g+rwx"
}


function files.file_remove_group_read_only {
  __verify_nr_args "$#" 1 files.file_remove_group_read_only
  local target
  target="$1"
  files.file_set_perms "$target" "g-r"
}

function files.file_remove_group_write_only {
  __verify_nr_args "$#" 1 files.file_remove_group_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "g-w"
}

function files.file_remove_group_execute_only {
  __verify_nr_args "$#" 1 files.file_remove_group_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "g-x"
}

function files.file_remove_group_read_write_only {
  __verify_nr_args "$#" 1 files.file_remove_group_read_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "g-rw"
}

function files.file_remove_group_read_execute_only {
  __verify_nr_args "$#" 1 files.file_remove_group_read_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "g-rx"
}

function files.file_remove_group_write_execute_only {
  __verify_nr_args "$#" 1 files.file_remove_group_write_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "g-wx"
}

function files.file_remove_group_read_write_execute_only {
  __verify_nr_args "$#" 1 files.file_remove_group_read_write_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "g-rwx"
}