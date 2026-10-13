#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.3.0
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1791901074
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging
require class/.internal

# Classes for bash. They are not really classes, as the blog post says: a list
# of definitions, a list of instances and functions that make the two meet.
#
#   class.define Person person_new          # the constructor is a function, or none
#   class.define_method Person greet person_greet
#   class.new Person alice "Alice" 30        # makes the instance alice, calls person_new alice Alice 30
#   class.define_property Person nickname "none"   # a property that every instance has, with a default
#   alice.name                               # prints the property name
#   alice.name "Alice Cooper"                # sets it
#   alice.greet "Hello"                      # calls person_greet alice Hello
#
# A method is a function that is given the name of the instance first and then
# its arguments, a constructor is one too. The third argument of define_method
# can also be the code of the method instead of the name of a function.
#
# class.new, class.set and the other functions that change something need to
# be called directly: in $(...) they would change a copy of the registries that
# is thrown away. Reading, like alice.name, works in $(...) as well.
#
# The blog post planned for alice.name=Cooper. That does not exist in bash:
# a word like that is not a variable assignment because of the dot, so bash
# looks for a command by that name and a handler for that case
# (command_not_found_handle) runs in a subshell and can change nothing.

# Sorts the lines of stdin, without duplicates, in plain bash: lists of
# properties and methods are short
function class._sort {
	local line other i j
	local -a lines sorted
	local -A seen
	mapfile -t lines
	sorted=()
	for line in "${lines[@]}"; do
		[ -z "${seen[$line]+_}" ] || continue
		seen["$line"]=1
		i=${#sorted[@]}
		sorted+=("$line")
		for ((j = i; j > 0; j--)); do
			if [[ "${sorted[j - 1]}" > "${sorted[j]}" ]]; then
				other="${sorted[j - 1]}"
				sorted[j - 1]="${sorted[j]}"
				sorted[j]="$other"
			else
				break
			fi
		done
	done
	[ "${#sorted[@]}" -eq 0 ] || printf '%s\n' "${sorted[@]}"
}

# Defines a class. The constructor is optional, a class without one gets
# the constructor of the class it extends.
# Usage: class.define <class> [constructor function]
function class.define {
	if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
		logging.error "class.define: usage is class.define <CLASS> [CONSTRUCTOR]"
		return 1
	fi
	class._verify_name "$1" || return 1
	if [ -n "${CRUCIBLE_CLASS_REGISTRY[$1]+_}" ]; then
		logging.error "The class $1 is defined already"
		return 1
	fi
	if [ -n "${2:-}" ] && ! declare -F "$2" >/dev/null; then
		logging.error "$2 is not a function"
		return 1
	fi
	__add_to_global_class_registry "$1" "${2:-}"
}

# Makes a class extend another. Methods, static methods and the constructor
# that the class does not have itself are taken from the class it extends.
# Usage: class.extends <class> <parent>
function class.extends {
	__verify_nr_args "$#" 2 class.extends
	local ancestor
	class._verify_class "$1" || return 1
	class._verify_class "$2" || return 1
	while read -r ancestor; do
		if [ "$ancestor" = "$1" ]; then
			logging.error "$1 cannot extend $2: that would make $1 its own ancestor"
			return 1
		fi
	done < <(class._lineage "$2")
	__add_to_global_class_registry "$1|@parent" "$2"
}

# Sets _class_function to the function for a method: the fourth argument when
# that is the name of a function, otherwise a function made of it as code. The
# code gets the instance as $1.
# Usage: class._function_for <class> <kind> <name> <function or code>
function class._function_for {
	if declare -F "$4" >/dev/null; then
		_class_function="$4"
		return 0
	fi
	_class_function="__crucible_class_${1}_${2}${3}"
	class._define_function "$_class_function" "$4"
}

# Usage: class.define_method <class> <name> <function or code>
function class.define_method {
	__verify_nr_args "$#" 3 class.define_method
	local instance
	class._verify_class "$1" || return 1
	class._verify_name "$2" || return 1
	if [ -n "${CRUCIBLE_CLASS_REGISTRY["$1|#$2"]+_}" ]; then
		logging.error "$2 is a property of $1, it cannot be a method"
		return 1
	fi
	class._function_for "$1" "" "$2" "$3" || return 1
	__add_to_global_class_registry "$1|$2" "$_class_function"
	# Instances that exist already get the function too
	while read -r instance; do
		class._define_function "$instance.$2" "class.invoke '$instance' '$2' \"\$@\"" || return 1
	done < <(class.instances "$1")
}

# A static method belongs to the class and not to an instance. It is called as
# Class.name, or with class.invoke_static, and gets no instance.
# Usage: class.define_static_method <class> <name> <function or code>
function class.define_static_method {
	__verify_nr_args "$#" 3 class.define_static_method
	class._verify_class "$1" || return 1
	class._verify_name "$2" || return 1
	class._function_for "$1" "STATIC_" "$2" "$3" || return 1
	class._define_function "$1.$2" "class.invoke_static '$1' '$2' \"\$@\"" || return 1
	__add_to_global_class_registry "$1|STATIC_$2" "$_class_function"
}

# Declares a property of a class: every instance gets the function
# instance.property from the start, so that instance.property value works the
# first time, and the default value when there is one. Without a declaration
# the function only exists once class.set made the property.
# Usage: class.define_property <class> <property> [default]
function class.define_property {
	if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
		logging.error "class.define_property: usage is class.define_property <CLASS> <PROPERTY> [DEFAULT]"
		return 1
	fi
	local instance
	class._verify_class "$1" || return 1
	class._verify_name "$2" || return 1
	if class._find_method "$1" "$2" >/dev/null; then
		logging.error "$2 is a method of $1, it cannot be a property"
		return 1
	fi
	# The first character tells whether there is a default: 1 is yes, 0 is no
	if [ "$#" -eq 3 ]; then
		__add_to_global_class_registry "$1|#$2" "1$3"
	else
		__add_to_global_class_registry "$1|#$2" "0"
	fi
	while read -r instance; do
		class._expose_properties "$instance" "$1" || return 1
	done < <(class.instances "$1")
}

# Gives an instance the functions and defaults of the properties its class declares.
# What the instance has already is not touched.
function class._expose_properties {
	local class key property declaration
	while read -r class; do
		for key in "${!CRUCIBLE_CLASS_REGISTRY[@]}"; do
			[[ "$key" == "$class|#"* ]] || continue
			property="${key#"$class|#"}"
			declaration="${CRUCIBLE_CLASS_REGISTRY[$key]}"
			class._define_function "$1.$property" "if [ \"\$#\" -eq 0 ]; then class.get '$1' '$property'; else class.set '$1' '$property' \"\$1\"; fi" || return 1
			if [ "${declaration:0:1}" = "1" ] && [ -z "${CRUCIBLE_INSTANCE_REGISTRY["$1|$property"]+_}" ]; then
				CRUCIBLE_INSTANCE_REGISTRY["$1|$property"]="${declaration:1}"
			fi
		done
	done < <(class._lineage "$2")
}

# Makes the functions with which an instance is used: instance.method
function class._expose_methods {
	local class key method
	while read -r class; do
		for key in "${!CRUCIBLE_CLASS_REGISTRY[@]}"; do
			if [[ "$key" == "$class|"* && "$key" != *"|STATIC_"* && "$key" != *"|@parent" && "$key" != *"|#"* ]]; then
				method="${key#"$class|"}"
				class._define_function "$1.$method" "class.invoke '$1' '$method' \"\$@\"" || return 1
			fi
		done
	done < <(class._lineage "$2")
}

# Makes an instance of a class with the name given. The constructor is called
# with the name of the instance and the arguments that are left.
# Usage: class.new <class> <instance> [constructor argument]...
function class.new {
	if [ "$#" -lt 2 ]; then
		logging.error "class.new: usage is class.new <CLASS> <INSTANCE> [ARGUMENT]..."
		return 1
	fi
	local class instance constructor
	class="$1"
	instance="$2"
	shift 2
	class._verify_class "$class" || return 1
	class._verify_name "$instance" || return 1
	if [ -n "${CRUCIBLE_INSTANCE_REGISTRY[$instance]+_}" ]; then
		logging.error "The instance $instance exists already"
		return 1
	fi
	__add_to_global_instance_registry "$instance" "$class"
	if ! class._expose_methods "$instance" "$class" || ! class._expose_properties "$instance" "$class"; then
		class.delete "$instance"
		return 1
	fi
	constructor="$(class._find_constructor "$class")"
	if [ -n "$constructor" ]; then
		"$constructor" "$instance" "$@" || {
			class.delete "$instance"
			return 1
		}
	fi
}

# Prints the constructor of the class or of the nearest class it extends that has one
function class._find_constructor {
	local class
	while read -r class; do
		if [ -n "${CRUCIBLE_CLASS_REGISTRY[$class]}" ]; then
			printf '%s\n' "${CRUCIBLE_CLASS_REGISTRY[$class]}"
			return 0
		fi
	done < <(class._lineage "$1")
}

# Calls the constructor of one class on an instance, to let a class that
# extends another one run the constructor of that class first.
# Usage: class.construct <class> <instance> [argument]...
function class.construct {
	if [ "$#" -lt 2 ]; then
		logging.error "class.construct: usage is class.construct <CLASS> <INSTANCE> [ARGUMENT]..."
		return 1
	fi
	local class instance constructor
	class="$1"
	instance="$2"
	class._verify_class "$class" || return 1
	class._verify_instance "$instance" || return 1
	shift 2
	constructor="$(class._find_constructor "$class")"
	if [ -n "$constructor" ]; then
		"$constructor" "$instance" "$@"
	fi
}

# Calls a method of an instance, the method of the class or of the nearest
# class it extends.
# Usage: class.invoke <instance> <method> [argument]...
function class.invoke {
	if [ "$#" -lt 2 ]; then
		logging.error "class.invoke: usage is class.invoke <INSTANCE> <METHOD> [ARGUMENT]..."
		return 1
	fi
	local instance method function_name
	instance="$1"
	method="$2"
	class._verify_instance "$instance" || return 1
	shift 2
	function_name="$(class._find_method "${CRUCIBLE_INSTANCE_REGISTRY[$instance]}" "$method")" || {
		logging.error "$instance has no method $method"
		return 127
	}
	"$function_name" "$instance" "$@"
}

# Calls the method as a particular class has it, which is how a method of a
# class that extends another one calls the method that it replaces.
# Usage: class.invoke_as <class> <instance> <method> [argument]...
function class.invoke_as {
	if [ "$#" -lt 3 ]; then
		logging.error "class.invoke_as: usage is class.invoke_as <CLASS> <INSTANCE> <METHOD> [ARGUMENT]..."
		return 1
	fi
	local class instance method function_name
	class="$1"
	instance="$2"
	method="$3"
	class._verify_class "$class" || return 1
	class._verify_instance "$instance" || return 1
	shift 3
	function_name="$(class._find_method "$class" "$method")" || {
		logging.error "$class has no method $method"
		return 127
	}
	"$function_name" "$instance" "$@"
}

# Usage: class.invoke_static <class> <method> [argument]...
function class.invoke_static {
	if [ "$#" -lt 2 ]; then
		logging.error "class.invoke_static: usage is class.invoke_static <CLASS> <METHOD> [ARGUMENT]..."
		return 1
	fi
	local class method function_name
	class="$1"
	method="$2"
	class._verify_class "$class" || return 1
	shift 2
	function_name="$(class._find_method "$class" "$method" STATIC_)" || {
		logging.error "$class has no static method $method"
		return 127
	}
	"$function_name" "$@"
}

# Prints the value of a property
# Usage: class.get <instance> <property>
function class.get {
	__verify_nr_args "$#" 2 class.get
	class._verify_instance "$1" || return 1
	if [ -z "${CRUCIBLE_INSTANCE_REGISTRY["$1|$2"]+_}" ]; then
		return 1
	fi
	printf '%s\n' "${CRUCIBLE_INSTANCE_REGISTRY["$1|$2"]}"
}

# Sets a property, and with it the function instance.property that gets and sets it.
# A property cannot have the name of a method.
# Usage: class.set <instance> <property> <value>
function class.set {
	__verify_nr_args "$#" 3 class.set
	class._verify_instance "$1" || return 1
	class._verify_name "$2" || return 1
	if class._find_method "${CRUCIBLE_INSTANCE_REGISTRY[$1]}" "$2" >/dev/null; then
		logging.error "$2 is a method of ${CRUCIBLE_INSTANCE_REGISTRY[$1]}, it cannot be a property"
		return 1
	fi
	if [ -z "${CRUCIBLE_INSTANCE_REGISTRY["$1|$2"]+_}" ]; then
		class._define_function "$1.$2" "if [ \"\$#\" -eq 0 ]; then class.get '$1' '$2'; else class.set '$1' '$2' \"\$1\"; fi" || return 1
	fi
	CRUCIBLE_INSTANCE_REGISTRY["$1|$2"]="$3"
}

function class.has {
	__verify_nr_args "$#" 2 class.has
	class._verify_instance "$1" || return 1
	[ -n "${CRUCIBLE_INSTANCE_REGISTRY["$1|$2"]+_}" ]
}

# Prints the names of the properties of an instance, in no particular order
function class.properties {
	__verify_nr_args "$#" 1 class.properties
	local key
	class._verify_instance "$1" || return 1
	for key in "${!CRUCIBLE_INSTANCE_REGISTRY[@]}"; do
		if [[ "$key" == "$1|"* ]]; then
			printf '%s\n' "${key#"$1|"}"
		fi
	done
}

# Prints name=value for every property of an instance, sorted by name
function class.dump {
	__verify_nr_args "$#" 1 class.dump
	local property
	class._verify_instance "$1" || return 1
	while read -r property; do
		printf '%s=%s\n' "$property" "${CRUCIBLE_INSTANCE_REGISTRY["$1|$property"]}"
	done < <(class.properties "$1" | class._sort)
}

# Removes an instance with its properties and its functions
function class.delete {
	__verify_nr_args "$#" 1 class.delete
	local key
	class._verify_instance "$1" || return 1
	for key in "${!CRUCIBLE_CLASS_FUNCTIONS[@]}"; do
		if [[ "$key" == "$1."* ]]; then
			class._remove_function "$key"
		fi
	done
	for key in "${!CRUCIBLE_INSTANCE_REGISTRY[@]}"; do
		if [[ "$key" == "$1|"* ]]; then
			unset 'CRUCIBLE_INSTANCE_REGISTRY[$key]'
		fi
	done
	unset 'CRUCIBLE_INSTANCE_REGISTRY[$1]'
}

# Succeeds when the instance is of the class, or of a class that extends it
# Usage: class.instance_of <instance> <class>
function class.instance_of {
	__verify_nr_args "$#" 2 class.instance_of
	local ancestor
	class._verify_instance "$1" || return 1
	while read -r ancestor; do
		if [ "$ancestor" = "$2" ]; then
			return 0
		fi
	done < <(class._lineage "${CRUCIBLE_INSTANCE_REGISTRY[$1]}")
	return 1
}

function class.class_of {
	__verify_nr_args "$#" 1 class.class_of
	class._verify_instance "$1" || return 1
	printf '%s\n' "${CRUCIBLE_INSTANCE_REGISTRY[$1]}"
}

# Prints the instances, of one class when it is given, sorted by name
function class.instances {
	local key
	for key in "${!CRUCIBLE_INSTANCE_REGISTRY[@]}"; do
		[[ "$key" == *"|"* ]] && continue
		if [ -z "${1:-}" ] || class.instance_of "$key" "$1"; then
			printf '%s\n' "$key"
		fi
	done | class._sort
}

# Prints the methods of a class, with those of the classes it extends, sorted by name
function class.methods {
	__verify_nr_args "$#" 1 class.methods
	local class key
	class._verify_class "$1" || return 1
	while read -r class; do
		for key in "${!CRUCIBLE_CLASS_REGISTRY[@]}"; do
			if [[ "$key" == "$class|"* && "$key" != *"|STATIC_"* && "$key" != *"|@parent" && "$key" != *"|#"* ]]; then
				printf '%s\n' "${key#"$class|"}"
			fi
		done
	done < <(class._lineage "$1") | class._sort
}
