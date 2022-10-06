#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require class/.internal
require arrays/arrays

function class.define {
	__verify_nr_args "$#" 2 class.new
	local name constructor
	name="$1"
	constructor="$2"
	# wrap or prefix with code to always inject into instance registry
	__add_to_global_class_registry "$name" "$constructor"
}

function class.define_method {
	__verify_nr_args "$#" 3 class.define_method
	local class method_name method
	class="$1"
	method_name="$2"
	method="$3"
	__add_to_global_class_registry "$class|$method_name" "$method"
}

function class.define_static_method {
	__verify_nr_args "$#" 3 class.define_static_method
	local class method_name method
	class="$1"
	method_name="STATIC_$2"
	method="$3"
	__add_to_global_class_registry "$class|$method_name" "$method"
}

function class.invoke_method {
	case "$#" in
	0 | 1)
		logging.error "class.invoke_method"
		logging.error "Need at least two arguments: class_name method_name [method_args]"
		logging.error "Only got: $#"
		exit 1
		;;
	2)
		local class_name method_name
		class_name="$1"
		method_name="$2"
		# add logic if method is prefixed with STATIC then operate on CLASS Registry instead of Instance
		logging.info "Just execute method: $class_name|$method_name"
		;;
	*)
		# add logic if method is prefixed with STATIC then operate on CLASS Registry instead of Instance
		# eval "function A_greeting { $(maps.get CRUCIBLE_CLASS_REGISTRY 'A|greeting') ; }; A_greeting Sir Googide; unset A_greeting"
		arrays.transform_into_array args
		arrays.add_all args "$@"
		local class_name method_name i
		arrays.transform_into_array method_args
		class_name=$(arrays.get args 0)
		method_name=$(arrays.get args 1)
		for ((i = 1; i < ${#args[@]}; i++)); do
			arrays.add method_args $(arrays.get args "$i")
		done
		unset args
		logging.info "Execute method name: ${method_name} with method_args: ${method_args[*]}"
		unset method_args
		;;
	esac
}

function class.new {
	# here we instantiate a class
	# call constructor method (eval)
	# create uuid
	# add mapping to instance registry
	true
}
