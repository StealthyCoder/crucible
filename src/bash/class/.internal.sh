#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging

# What is known about classes. The keys are:
#   Class            the constructor function of the class, empty when it has none
#   Class|name       the function of the method name
#   Class|STATIC_name the function of the static method name
#   Class|@parent    the class that Class extends
declare -gA CRUCIBLE_CLASS_REGISTRY
# What is known about instances. The keys are:
#   instance         the class of the instance
#   instance|name    the value of the property name
declare -gA CRUCIBLE_INSTANCE_REGISTRY
# The names of the functions that were made for classes and instances, so that
# they can be told from functions that are somebody else's
declare -gA CRUCIBLE_CLASS_FUNCTIONS

function __setup_global_registry {
	if ! declare -p CRUCIBLE_CLASS_REGISTRY &>>/dev/null; then
		declare -Agx CRUCIBLE_CLASS_REGISTRY=()
	fi
	if ! declare -p CRUCIBLE_INSTANCE_REGISTRY &>>/dev/null; then
		declare -Agx CRUCIBLE_INSTANCE_REGISTRY=()
	fi
}

function __add_to_global_class_registry {
	__verify_nr_args "$#" 2 add_to_global_class_registry
	CRUCIBLE_CLASS_REGISTRY["$1"]="$2"
}

function __add_to_global_instance_registry {
	__verify_nr_args "$#" 2 add_to_global_instance_registry
	CRUCIBLE_INSTANCE_REGISTRY["$1"]="$2"
}

# A name that is safe to put in a function name and in the eval that makes it
function class._verify_name {
	if ! [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
		logging.error "Not a valid name, use letters, digits and underscores: $1"
		return 1
	fi
}

function class._verify_class {
	if [ -z "${CRUCIBLE_CLASS_REGISTRY[$1]+_}" ]; then
		logging.error "There is no class named $1"
		return 1
	fi
}

function class._verify_instance {
	if [ -z "${CRUCIBLE_INSTANCE_REGISTRY[$1]+_}" ]; then
		logging.error "There is no instance named $1"
		return 1
	fi
}

# Defines a function that is made for a class or an instance, unless the name
# is the name of a function that is not ours
# Usage: class._define_function <name> <body>
function class._define_function {
	if declare -F "$1" >/dev/null && [ -z "${CRUCIBLE_CLASS_FUNCTIONS[$1]+_}" ]; then
		logging.error "$1 is a function already, it would be overwritten"
		return 1
	fi
	eval "function $1 { $2; }"
	CRUCIBLE_CLASS_FUNCTIONS["$1"]=1
}

function class._remove_function {
	if [ -n "${CRUCIBLE_CLASS_FUNCTIONS[$1]+_}" ]; then
		unset -f "$1"
		unset 'CRUCIBLE_CLASS_FUNCTIONS[$1]'
	fi
}

# Prints the function of a method of the class or of the class it extends,
# nearest first. The kind is "" for a method and STATIC_ for a static method.
# Usage: class._find_method <class> <name> [kind]
function class._find_method {
	local class depth
	class="$1"
	depth=0
	while [ -n "$class" ] && [ "$depth" -lt 100 ]; do
		if [ -n "${CRUCIBLE_CLASS_REGISTRY["$class|${3:-}$2"]+_}" ]; then
			printf '%s\n' "${CRUCIBLE_CLASS_REGISTRY["$class|${3:-}$2"]}"
			return 0
		fi
		class="${CRUCIBLE_CLASS_REGISTRY["$class|@parent"]:-}"
		depth=$((depth + 1))
	done
	return 1
}

# Prints the class, then the class it extends, and so on
function class._lineage {
	local class depth
	class="$1"
	depth=0
	while [ -n "$class" ] && [ "$depth" -lt 100 ]; do
		printf '%s\n' "$class"
		class="${CRUCIBLE_CLASS_REGISTRY["$class|@parent"]:-}"
		depth=$((depth + 1))
	done
}

__setup_global_registry
