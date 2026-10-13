#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.3.0
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1791901074
### CRUCIBLE META DATA ###

declare -gA CRUCIBLE_LOADED_MODULES

function __fetch_module {
	local module target location
	module="$1"
	target="$2"
	location="$3"
	if ! wget --no-cache -q -O "$target" "https://raw.githubusercontent.com/StealthyCoder/crucible/$location/src/bash/${module%.sh}.sh"; then
		rm -f "$target"
		echo "Could not download module $module from $location." >&2
		exit 1
	fi
}

function require {
	local local_crucible_version shared_crucible_version shared_location module_name module_dir module_file crucible_location slashes
	if [ -z "$1" ]; then
		echo "Module to require has to be specified."
		exit 1
	fi
	# A module is loaded once, this keeps diamond dependencies cheap and
	# makes sure a base module never overwrites its already loaded safe variant
	if [ -n "${CRUCIBLE_LOADED_MODULES[${1%.sh}]+_}" ]; then
		return 0
	fi
	local_crucible_version="$(grep '^version=' .crucible | cut -d'=' -f 2-)"
	shared_crucible_version="$(grep '^version=' "$(grep '^shared_dir=' .crucible | cut -d'=' -f 2-)"/.crucible | cut -d'=' -f 2-)"
	crucible_location="$(grep '^location=' .crucible | cut -d'=' -f 2-)"
	if [ "$local_crucible_version" != "$shared_crucible_version" ]; then
		echo "Versions out of sync. Please run crucible update."
	fi
	shared_location="$(grep '^shared_dir=' .crucible | cut -d'=' -f 2-)/"
	slashes="$(echo "$1" | grep -o '/' | wc -l)"
	module_dir="$(echo "$1" | cut -d'/' -f1-"$slashes")"
	module_name="$(echo "$1" | cut -d'/' -f"$(("$slashes" + 1))")"
	module_file="$shared_location$module_dir/${module_name%.sh}.sh"
	if [ ! -d "$shared_location$module_dir" ]; then
		mkdir -p "$shared_location$module_dir"
	fi
	if [ -f "$module_file" ]; then
		local module_version
		module_version="$(grep '^# CRUCIBLE_VERSION=' "$module_file" | cut -d'=' -f 2-)"
		if [ "$module_version" != "$local_crucible_version" ]; then
			__fetch_module "$1" "$module_file" "$crucible_location"
		fi
	else
		__fetch_module "$1" "$module_file" "$crucible_location"
	fi
	# Marked before sourcing so a circular require terminates
	CRUCIBLE_LOADED_MODULES[${1%.sh}]=1
	# shellcheck disable=SC1090
	source "$module_file"
}
