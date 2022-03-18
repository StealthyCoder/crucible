#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require io/files/dirs

function dirs.dir_set_group_read_only_clear {
	__verify_nr_args "$#" 1 dirs.dir_set_group_read_only_clear
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g=r,ug-rxw"
}

function dirs.dir_set_group_read_only {
	__verify_nr_args "$#" 1 dirs.dir_set_group_read_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g=r"
}

function dirs.dir_set_user_group_read_only_clear {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_read_only_clear
	local target
	target="$1"
	dirs.dir_set_perms "$target" "ug=r,o-rxw"
}

function dirs.dir_set_user_group_read_only {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_read_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "ug=r"
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

function dirs.dir_set_group_write_only_clear {
	__verify_nr_args "$#" 1 dirs.dir_set_group_write_only_clear
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g=w,ug-rxw"
}

function dirs.dir_set_group_write_only {
	__verify_nr_args "$#" 1 dirs.dir_set_group_write_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g=w"
}

function dirs.dir_set_user_group_write_only_clear {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_write_only_clear
	local target
	target="$1"
	dirs.dir_set_perms "$target" "ug=w,o-rxw"
}

function dirs.dir_set_user_group_write_only {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_write_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "ug=w"
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

function dirs.dir_set_group_execute_only_clear {
	__verify_nr_args "$#" 1 dirs.dir_set_group_execute_only_clear
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g=x,ug-rxw"
}

function dirs.dir_set_group_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_set_group_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g=x"
}

function dirs.dir_set_user_group_execute_only_clear {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_execute_only_clear
	local target
	target="$1"
	dirs.dir_set_perms "$target" "ug=x,o-rxw"
}

function dirs.dir_set_user_group_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "ug=x"
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

function dirs.dir_add_group_read_only {
	__verify_nr_args "$#" 1 dirs.dir_add_group_read_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g+r"
}

function dirs.dir_add_group_write_only {
	__verify_nr_args "$#" 1 dirs.dir_add_group_write_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g+w"
}

function dirs.dir_add_group_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_add_group_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g+x"
}

function dirs.dir_add_group_read_write_only {
	__verify_nr_args "$#" 1 dirs.dir_add_group_read_write_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g+rw"
}

function dirs.dir_add_group_read_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_add_group_read_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g+rx"
}

function dirs.dir_add_group_write_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_add_group_write_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g+wx"
}

function dirs.dir_add_group_read_write_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_add_group_read_write_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g+rwx"
}

function dirs.dir_remove_group_read_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_read_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g-r"
}

function dirs.dir_remove_group_write_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_write_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g-w"
}

function dirs.dir_remove_group_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g-x"
}

function dirs.dir_remove_group_read_write_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_read_write_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g-rw"
}

function dirs.dir_remove_group_read_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_read_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g-rx"
}

function dirs.dir_remove_group_write_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_write_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g-wx"
}

function dirs.dir_remove_group_read_write_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_read_write_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "g-rwx"
}

# Recursive

function dirs.dir_set_group_read_only_clear_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_group_read_only_clear_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g=r,ug-rxw"
}

function dirs.dir_set_group_read_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_group_read_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g=r"
}

function dirs.dir_set_user_group_read_only_clear_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_read_only_clear_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "ug=r,o-rxw"
}

function dirs.dir_set_user_group_read_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_read_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "ug=r"
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

function dirs.dir_set_group_write_only_clear_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_group_write_only_clear_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g=w,ug-rxw"
}

function dirs.dir_set_group_write_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_group_write_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g=w"
}

function dirs.dir_set_user_group_write_only_clear_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_write_only_clear_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "ug=w,o-rxw"
}

function dirs.dir_set_user_group_write_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_write_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "ug=w"
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

function dirs.dir_set_group_execute_only_clear_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_group_execute_only_clear_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g=x,ug-rxw"
}

function dirs.dir_set_group_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_group_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g=x"
}

function dirs.dir_set_user_group_execute_only_clear_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_execute_only_clear_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "ug=x,o-rxw"
}

function dirs.dir_set_user_group_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_group_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "ug=x"
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

function dirs.dir_add_group_read_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_group_read_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g+r"
}

function dirs.dir_add_group_write_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_group_write_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g+w"
}

function dirs.dir_add_group_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_group_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g+x"
}

function dirs.dir_add_group_read_write_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_group_read_write_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g+rw"
}

function dirs.dir_add_group_read_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_group_read_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g+rx"
}

function dirs.dir_add_group_write_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_group_write_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g+wx"
}

function dirs.dir_add_group_read_write_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_group_read_write_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g+rwx"
}

function dirs.dir_remove_group_read_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_read_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g-r"
}

function dirs.dir_remove_group_write_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_write_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g-w"
}

function dirs.dir_remove_group_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g-x"
}

function dirs.dir_remove_group_read_write_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_read_write_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g-rw"
}

function dirs.dir_remove_group_read_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_read_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g-rx"
}

function dirs.dir_remove_group_write_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_write_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g-wx"
}

function dirs.dir_remove_group_read_write_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_group_read_write_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "g-rwx"
}
