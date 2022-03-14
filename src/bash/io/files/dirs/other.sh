#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.2.7
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1647268068
### CRUCIBLE META DATA ###

require core/.internal
require io/files/dirs

function dirs.dir_set_other_read_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_other_read_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o=r,ug-rxw"
}

function dirs.dir_set_other_read_only {
  __verify_nr_args "$#" 1 dirs.dir_set_other_read_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o=r"
}

function dirs.dir_set_user_other_read_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_read_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "uo=r,g-rxw"
}

function dirs.dir_set_user_other_read_only {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_read_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "uo=r"
}

function dirs.dir_set_group_other_read_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_read_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "go=r,u-rxw"
}

function dirs.dir_set_group_other_read_only {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_read_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "go=r"
}

function dirs.dir_set_other_write_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_other_write_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o=w,ug-rxw"
}

function dirs.dir_set_other_write_only {
  __verify_nr_args "$#" 1 dirs.dir_set_other_write_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o=w"
}

function dirs.dir_set_user_other_write_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_write_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "uo=w,g-rxw"
}

function dirs.dir_set_user_other_write_only {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_write_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "uo=w"
}

function dirs.dir_set_group_other_write_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_write_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "go=w,u-rxw"
}

function dirs.dir_set_group_other_write_only {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_write_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "go=w"
}

function dirs.dir_set_other_execute_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_other_execute_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o=x,ug-rxw"
}

function dirs.dir_set_other_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_set_other_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o=x"
}

function dirs.dir_set_user_other_execute_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_execute_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "uo=x,g-rxw"
}

function dirs.dir_set_user_other_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "uo=x"
}

function dirs.dir_set_group_other_execute_only_clear {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_execute_only_clear
  local target
  target="$1"
  dirs.dir_set_perms "$target" "go=x,u-rxw"
}

function dirs.dir_set_group_other_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "go=x"
}

function dirs.dir_add_other_read_only {
  __verify_nr_args "$#" 1 dirs.dir_add_other_read_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o+r"
}

function dirs.dir_add_other_write_only {
  __verify_nr_args "$#" 1 dirs.dir_add_other_write_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o+w"
}

function dirs.dir_add_other_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_add_other_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o+x"
}

function dirs.dir_add_other_read_write_only {
  __verify_nr_args "$#" 1 dirs.dir_add_other_read_write_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o+rw"
}

function dirs.dir_add_other_read_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_add_other_read_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o+rx"
}

function dirs.dir_add_group_write_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_add_group_write_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "g+wx"
}

function dirs.dir_add_other_read_write_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_add_other_read_write_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o+rwx"
}


function dirs.dir_remove_other_read_only {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_read_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o-r"
}

function dirs.dir_remove_other_write_only {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_write_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o-w"
}

function dirs.dir_remove_other_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o-x"
}

function dirs.dir_remove_other_read_write_only {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_read_write_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o-rw"
}

function dirs.dir_remove_other_read_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_read_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o-rx"
}

function dirs.dir_remove_other_write_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_write_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o-wx"
}

function dirs.dir_remove_other_read_write_execute_only {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_read_write_execute_only
  local target
  target="$1"
  dirs.dir_set_perms "$target" "o-rwx"
}

## Recursive functions

function dirs.dir_set_other_read_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_other_read_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o=r,ug-rxw"
}

function dirs.dir_set_other_read_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_other_read_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o=r"
}

function dirs.dir_set_user_other_read_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_read_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "uo=r,g-rxw"
}

function dirs.dir_set_user_other_read_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_read_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "uo=r"
}

function dirs.dir_set_group_other_read_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_read_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "go=r,u-rxw"
}

function dirs.dir_set_group_other_read_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_read_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "go=r"
}

function dirs.dir_set_other_write_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_other_write_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o=w,ug-rxw"
}

function dirs.dir_set_other_write_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_other_write_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o=w"
}

function dirs.dir_set_user_other_write_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_write_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "uo=w,g-rxw"
}

function dirs.dir_set_user_other_write_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_write_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "uo=w"
}

function dirs.dir_set_group_other_write_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_write_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "go=w,u-rxw"
}

function dirs.dir_set_group_other_write_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_write_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "go=w"
}

function dirs.dir_set_other_execute_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_other_execute_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o=x,ug-rxw"
}

function dirs.dir_set_other_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_other_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o=x"
}

function dirs.dir_set_user_other_execute_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_execute_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "uo=x,g-rxw"
}

function dirs.dir_set_user_other_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_user_other_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "uo=x"
}

function dirs.dir_set_group_other_execute_only_clear_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_execute_only_clear_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "go=x,u-rxw"
}

function dirs.dir_set_group_other_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_set_group_other_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "go=x"
}

function dirs.dir_add_other_read_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_add_other_read_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o+r"
}

function dirs.dir_add_other_write_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_add_other_write_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o+w"
}

function dirs.dir_add_other_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_add_other_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o+x"
}

function dirs.dir_add_other_read_write_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_add_other_read_write_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o+rw"
}

function dirs.dir_add_other_read_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_add_other_read_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o+rx"
}

function dirs.dir_add_group_write_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_add_group_write_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "g+wx"
}

function dirs.dir_add_other_read_write_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_add_other_read_write_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o+rwx"
}


function dirs.dir_remove_other_read_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_read_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o-r"
}

function dirs.dir_remove_other_write_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_write_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o-w"
}

function dirs.dir_remove_other_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o-x"
}

function dirs.dir_remove_other_read_write_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_read_write_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o-rw"
}

function dirs.dir_remove_other_read_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_read_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o-rx"
}

function dirs.dir_remove_other_write_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_write_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o-wx"
}

function dirs.dir_remove_other_read_write_execute_only_recursive {
  __verify_nr_args "$#" 1 dirs.dir_remove_other_read_write_execute_only_recursive
  local target
  target="$1"
  dirs.dir_set_perms_recursive "$target" "o-rwx"
}