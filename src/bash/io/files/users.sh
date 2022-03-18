#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require io/files/files

function files.file_set_user_read_only_clear {
	__verify_nr_args "$#" 1 files.file_set_user_read_only_clear
	local target
	target="$1"
	files.file_set_perms "$target" "u=r,og-rxw"
}

function files.file_set_user_read_only {
	__verify_nr_args "$#" 1 files.file_set_user_read_only
	local target
	target="$1"
	files.file_set_perms "$target" "u=r"
}

function files.file_add_user_read_only {
	__verify_nr_args "$#" 1 files.file_add_user_read_only
	local target
	target="$1"
	files.file_set_perms "$target" "u+r"
}

function files.file_add_user_write_only {
	__verify_nr_args "$#" 1 files.file_add_user_write_only
	local target
	target="$1"
	files.file_set_perms "$target" "u+w"
}

function files.file_add_user_execute_only {
	__verify_nr_args "$#" 1 files.file_add_user_execute_only
	local target
	target="$1"
	files.file_set_perms "$target" "u+x"
}

function files.file_add_user_read_write_only {
	__verify_nr_args "$#" 1 files.file_add_user_read_write_only
	local target
	target="$1"
	files.file_set_perms "$target" "u+rw"
}

function files.file_add_user_read_execute_only {
	__verify_nr_args "$#" 1 files.file_add_user_read_execute_only
	local target
	target="$1"
	files.file_set_perms "$target" "u+rx"
}

function files.file_add_user_write_execute_only {
	__verify_nr_args "$#" 1 files.file_add_user_write_execute_only
	local target
	target="$1"
	files.file_set_perms "$target" "u+wx"
}

function files.file_add_user_read_write_execute_only {
	__verify_nr_args "$#" 1 files.file_add_user_read_write_execute_only
	local target
	target="$1"
	files.file_set_perms "$target" "u+rwx"
}

function files.file_remove_user_read_only {
	__verify_nr_args "$#" 1 files.file_remove_user_read_only
	local target
	target="$1"
	files.file_set_perms "$target" "u-r"
}

function files.file_remove_user_write_only {
	__verify_nr_args "$#" 1 files.file_remove_user_write_only
	local target
	target="$1"
	files.file_set_perms "$target" "u-w"
}

function files.file_remove_user_execute_only {
	__verify_nr_args "$#" 1 files.file_remove_user_execute_only
	local target
	target="$1"
	files.file_set_perms "$target" "u-x"
}

function files.file_remove_user_read_write_only {
	__verify_nr_args "$#" 1 files.file_remove_user_read_write_only
	local target
	target="$1"
	files.file_set_perms "$target" "u-rw"
}

function files.file_remove_user_read_execute_only {
	__verify_nr_args "$#" 1 files.file_remove_user_read_execute_only
	local target
	target="$1"
	files.file_set_perms "$target" "u-rx"
}

function files.file_remove_user_write_execute_only {
	__verify_nr_args "$#" 1 files.file_remove_user_write_execute_only
	local target
	target="$1"
	files.file_set_perms "$target" "u-wx"
}

function files.file_remove_user_read_write_execute_only {
	__verify_nr_args "$#" 1 files.file_remove_user_read_write_execute_only
	local target
	target="$1"
	files.file_set_perms "$target" "u-rwx"
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

function files.file_set_user_group_read_only_clear {
	__verify_nr_args "$#" 1 files.file_set_user_group_read_only_clear
	local target
	target="$1"
	files.file_set_perms "$target" "ug=r,o-rxw"
}

function files.file_set_user_group_read_only {
	__verify_nr_args "$#" 1 files.file_set_user_group_read_only
	local target
	target="$1"
	files.file_set_perms "$target" "ug=r"
}

function files.file_set_user_write_only_clear {
	__verify_nr_args "$#" 1 files.file_set_user_write_only_clear
	local target
	target="$1"
	files.file_set_perms "$target" "u=w,og-rxw"
}

function files.file_set_user_write_only {
	__verify_nr_args "$#" 1 files.file_set_user_write_only
	local target
	target="$1"
	files.file_set_perms "$target" "u=w"
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

function files.file_set_user_execute_only_clear {
	__verify_nr_args "$#" 1 files.file_set_user_execute_only_clear
	local target
	target="$1"
	files.file_set_perms "$target" "u=x,og-rxw"
}

function files.file_set_user_execute_only {
	__verify_nr_args "$#" 1 files.file_set_user_execute_only
	local target
	target="$1"
	files.file_set_perms "$target" "u=x"
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
