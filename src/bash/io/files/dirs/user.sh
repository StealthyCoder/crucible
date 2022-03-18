#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require io/files/dirs

function dirs.dir_set_user_read_only_clear {
	__verify_nr_args "$#" 1 dirs.dir_set_user_read_only_clear
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u=r,og-rxw"
}

function dirs.dir_set_user_read_only {
	__verify_nr_args "$#" 1 dirs.dir_set_user_read_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u=r"
}

function dirs.dir_add_user_read_only {
	__verify_nr_args "$#" 1 dirs.dir_add_user_read_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u+r"
}

function dirs.dir_add_user_write_only {
	__verify_nr_args "$#" 1 dirs.dir_add_user_write_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u+w"
}

function dirs.dir_add_user_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_add_user_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u+x"
}

function dirs.dir_add_user_read_write_only {
	__verify_nr_args "$#" 1 dirs.dir_add_user_read_write_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u+rw"
}

function dirs.dir_add_user_read_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_add_user_read_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u+rx"
}

function dirs.dir_add_user_write_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_add_user_write_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u+wx"
}

function dirs.dir_add_user_read_write_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_add_user_read_write_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u+rwx"
}

function dirs.dir_remove_user_read_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_read_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u-r"
}

function dirs.dir_remove_user_write_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_write_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u-w"
}

function dirs.dir_remove_user_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u-x"
}

function dirs.dir_remove_user_read_write_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_read_write_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u-rw"
}

function dirs.dir_remove_user_read_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_read_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u-rx"
}

function dirs.dir_remove_user_write_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_write_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u-wx"
}

function dirs.dir_remove_user_read_write_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_read_write_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u-rwx"
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

function dirs.dir_set_user_write_only_clear {
	__verify_nr_args "$#" 1 dirs.dir_set_user_write_only_clear
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u=w,og-rxw"
}

function dirs.dir_set_user_write_only {
	__verify_nr_args "$#" 1 dirs.dir_set_user_write_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u=w"
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

function dirs.dir_set_user_execute_only_clear {
	__verify_nr_args "$#" 1 dirs.dir_set_user_execute_only_clear
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u=x,og-rxw"
}

function dirs.dir_set_user_execute_only {
	__verify_nr_args "$#" 1 dirs.dir_set_user_execute_only
	local target
	target="$1"
	dirs.dir_set_perms "$target" "u=x"
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

# Recursive

function dirs.dir_set_user_read_only_clear_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_read_only_clear_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u=r,og-rxw"
}

function dirs.dir_set_user_read_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_read_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u=r"
}

function dirs.dir_add_user_read_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_user_read_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u+r"
}

function dirs.dir_add_user_write_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_user_write_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u+w"
}

function dirs.dir_add_user_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_user_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u+x"
}

function dirs.dir_add_user_read_write_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_user_read_write_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u+rw"
}

function dirs.dir_add_user_read_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_user_read_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u+rx"
}

function dirs.dir_add_user_write_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_user_write_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u+wx"
}

function dirs.dir_add_user_read_write_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_add_user_read_write_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u+rwx"
}

function dirs.dir_remove_user_read_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_read_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u-r"
}

function dirs.dir_remove_user_write_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_write_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u-w"
}

function dirs.dir_remove_user_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u-x"
}

function dirs.dir_remove_user_read_write_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_read_write_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u-rw"
}

function dirs.dir_remove_user_read_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_read_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u-rx"
}

function dirs.dir_remove_user_write_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_write_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u-wx"
}

function dirs.dir_remove_user_read_write_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_remove_user_read_write_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u-rwx"
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

function dirs.dir_set_user_write_only_clear_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_write_only_clear_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u=w,og-rxw"
}

function dirs.dir_set_user_write_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_write_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u=w"
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

function dirs.dir_set_user_execute_only_clear_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_execute_only_clear_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u=x,og-rxw"
}

function dirs.dir_set_user_execute_only_recursive {
	__verify_nr_args "$#" 1 dirs.dir_set_user_execute_only_recursive
	local target
	target="$1"
	dirs.dir_set_perms_recursive "$target" "u=x"
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
