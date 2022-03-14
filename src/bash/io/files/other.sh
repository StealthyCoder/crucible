#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.2.7
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1647268068
### CRUCIBLE META DATA ###

require core/.internal
require io/files/files

function files.file_set_other_read_only_clear {
  __verify_nr_args "$#" 1 files.file_set_other_read_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "o=r,ug-rxw"
}

function files.file_set_other_read_only {
  __verify_nr_args "$#" 1 files.file_set_other_read_only
  local target
  target="$1"
  files.file_set_perms "$target" "o=r"
}

function files.file_set_user_other_read_only_clear {
  __verify_nr_args "$#" 1 files.file_set_user_other_read_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "uo=r,g-rxw"
}

function files.file_set_user_other_read_only {
  __verify_nr_args "$#" 1 files.file_set_user_other_read_only
  local target
  target="$1"
  files.file_set_perms "$target" "uo=r"
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

function files.file_set_other_write_only_clear {
  __verify_nr_args "$#" 1 files.file_set_other_write_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "o=w,ug-rxw"
}

function files.file_set_other_write_only {
  __verify_nr_args "$#" 1 files.file_set_other_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "o=w"
}

function files.file_set_user_other_write_only_clear {
  __verify_nr_args "$#" 1 files.file_set_user_other_write_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "uo=w,g-rxw"
}

function files.file_set_user_other_write_only {
  __verify_nr_args "$#" 1 files.file_set_user_other_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "uo=w"
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

function files.file_set_other_execute_only_clear {
  __verify_nr_args "$#" 1 files.file_set_other_execute_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "o=x,ug-rxw"
}

function files.file_set_other_execute_only {
  __verify_nr_args "$#" 1 files.file_set_other_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "o=x"
}

function files.file_set_user_other_execute_only_clear {
  __verify_nr_args "$#" 1 files.file_set_user_other_execute_only_clear
  local target
  target="$1"
  files.file_set_perms "$target" "uo=x,g-rxw"
}

function files.file_set_user_other_execute_only {
  __verify_nr_args "$#" 1 files.file_set_user_other_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "uo=x"
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

function files.file_add_other_read_only {
  __verify_nr_args "$#" 1 files.file_add_other_read_only
  local target
  target="$1"
  files.file_set_perms "$target" "o+r"
}

function files.file_add_other_write_only {
  __verify_nr_args "$#" 1 files.file_add_other_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "o+w"
}

function files.file_add_other_execute_only {
  __verify_nr_args "$#" 1 files.file_add_other_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "o+x"
}

function files.file_add_other_read_write_only {
  __verify_nr_args "$#" 1 files.file_add_other_read_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "o+rw"
}

function files.file_add_other_read_execute_only {
  __verify_nr_args "$#" 1 files.file_add_other_read_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "o+rx"
}

function files.file_add_group_write_execute_only {
  __verify_nr_args "$#" 1 files.file_add_group_write_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "g+wx"
}

function files.file_add_other_read_write_execute_only {
  __verify_nr_args "$#" 1 files.file_add_other_read_write_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "o+rwx"
}


function files.file_remove_other_read_only {
  __verify_nr_args "$#" 1 files.file_remove_other_read_only
  local target
  target="$1"
  files.file_set_perms "$target" "o-r"
}

function files.file_remove_other_write_only {
  __verify_nr_args "$#" 1 files.file_remove_other_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "o-w"
}

function files.file_remove_other_execute_only {
  __verify_nr_args "$#" 1 files.file_remove_other_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "o-x"
}

function files.file_remove_other_read_write_only {
  __verify_nr_args "$#" 1 files.file_remove_other_read_write_only
  local target
  target="$1"
  files.file_set_perms "$target" "o-rw"
}

function files.file_remove_other_read_execute_only {
  __verify_nr_args "$#" 1 files.file_remove_other_read_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "o-rx"
}

function files.file_remove_other_write_execute_only {
  __verify_nr_args "$#" 1 files.file_remove_other_write_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "o-wx"
}

function files.file_remove_other_read_write_execute_only {
  __verify_nr_args "$#" 1 files.file_remove_other_read_write_execute_only
  local target
  target="$1"
  files.file_set_perms "$target" "o-rwx"
}