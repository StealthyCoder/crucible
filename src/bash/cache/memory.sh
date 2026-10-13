#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

# A nameref to the array of the cache is used as an array, shellcheck sees a string
# shellcheck disable=SC2178
require core/.internal
require logging/logging
require cache/.internal

# A cache in memory: an associative array in which entries can expire. Time
# is counted in whole seconds, so an entry that is stored with a ttl of 10
# is gone once the clock reaches the second 10 seconds after it was stored.
#
# A subshell, like $(...), works on a copy. Anything it changes is lost when it
# ends: put, remove and clear need to be called directly. get and has work in
# $(...) too, but then the removal of an expired entry and the statistics
# are lost along with the subshell. An expired entry is never returned though.
# Usage: cache.memory.create <name> [default ttl in seconds, 0 is forever]
function cache.memory.create {
	if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
		logging.error "cache.memory.create: usage is cache.memory.create <NAME> [TTL]"
		return 1
	fi
	cache._verify_name "$1" || return 1
	cache._verify_seconds "${2:-0}" || return 1
	if [ -z "${CRUCIBLE_CACHE_TTL[$1]+_}" ]; then
		if declare -p "$1" &>/dev/null; then
			logging.error "$1 is already in use as a variable"
			return 1
		fi
		declare -gA "$1"
	fi
	CRUCIBLE_CACHE_TTL["$1"]="${2:-0}"
}

# Usage: cache.memory.put <name> <key> <value> [ttl in seconds, 0 is forever]
function cache.memory.put {
	if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
		logging.error "cache.memory.put: usage is cache.memory.put <NAME> <KEY> <VALUE> [TTL]"
		return 1
	fi
	local now ttl
	cache._verify_exists "$1" || return 1
	local -n _cache_values="$1"
	cache._verify_key "$2" || return 1
	ttl="${4:-${CRUCIBLE_CACHE_TTL[$1]}}"
	cache._verify_seconds "$ttl" || return 1
	_cache_values["$2"]="$3"
	if [ "$ttl" -gt 0 ]; then
		cache._now now
		CRUCIBLE_CACHE_EXPIRES["$1|$2"]=$((now + ttl))
	else
		unset 'CRUCIBLE_CACHE_EXPIRES[$1|$2]'
	fi
}

# Succeeds when the entry exists and has not expired. An expired entry is removed.
function cache.memory.has {
	__verify_nr_args "$#" 2 cache.memory.has
	local now expires
	cache._verify_exists "$1" || return 1
	local -n _cache_values="$1"
	[ -n "${_cache_values["$2"]+_}" ] || return 1
	expires="${CRUCIBLE_CACHE_EXPIRES["$1|$2"]:-}"
	if [ -n "$expires" ]; then
		cache._now now
		if [ "$now" -ge "$expires" ]; then
			cache.memory.remove "$1" "$2"
			return 1
		fi
	fi
}

# Prints the value, fails when there is none
function cache.memory.get {
	__verify_nr_args "$#" 2 cache.memory.get
	cache._verify_exists "$1" || return 1
	local -n _cache_values="$1"
	if ! cache.memory.has "$1" "$2"; then
		cache._count "$1" misses
		return 1
	fi
	cache._count "$1" hits
	printf '%s\n' "${_cache_values["$2"]}"
}

function cache.memory.remove {
	__verify_nr_args "$#" 2 cache.memory.remove
	cache._verify_exists "$1" || return 1
	local -n _cache_values="$1"
	unset '_cache_values[$2]'
	unset 'CRUCIBLE_CACHE_EXPIRES[$1|$2]'
}

function cache.memory.clear {
	__verify_nr_args "$#" 1 cache.memory.clear
	local key
	cache._verify_exists "$1" || return 1
	local -n _cache_values="$1"
	_cache_values=()
	for key in "${!CRUCIBLE_CACHE_EXPIRES[@]}"; do
		if [[ "$key" == "$1|"* ]]; then
			unset 'CRUCIBLE_CACHE_EXPIRES[$key]'
		fi
	done
}

# Removes the cache, the entries and the statistics
function cache.memory.destroy {
	__verify_nr_args "$#" 1 cache.memory.destroy
	local key
	cache._verify_exists "$1" || return 1
	cache.memory.clear "$1"
	unset "$1"
	unset 'CRUCIBLE_CACHE_TTL[$1]'
	unset 'CRUCIBLE_CACHE_FILES[$1]'
	unset 'CRUCIBLE_CACHE_STATS[$1|hits]' 'CRUCIBLE_CACHE_STATS[$1|misses]'
}

# Prints the keys that have not expired, in no particular order
function cache.memory.keys {
	__verify_nr_args "$#" 1 cache.memory.keys
	local key
	cache._verify_exists "$1" || return 1
	local -n _cache_values="$1"
	for key in "${!_cache_values[@]}"; do
		if cache.memory.has "$1" "$key"; then
			printf '%s\n' "$key"
		fi
	done
}

function cache.memory.size {
	__verify_nr_args "$#" 1 cache.memory.size
	local key size
	cache._verify_exists "$1" || return 1
	local -n _cache_values="$1"
	size=0
	for key in "${!_cache_values[@]}"; do
		if cache.memory.has "$1" "$key"; then
			size=$((size + 1))
		fi
	done
	echo "$size"
}

# Removes the entries that have expired and prints how many there were
function cache.memory.evict_expired {
	__verify_nr_args "$#" 1 cache.memory.evict_expired
	local key before after
	cache._verify_exists "$1" || return 1
	local -n _cache_values="$1"
	before="${#_cache_values[@]}"
	for key in "${!_cache_values[@]}"; do
		cache.memory.has "$1" "$key" || true
	done
	after="${#_cache_values[@]}"
	echo $((before - after))
}

# Prints the seconds an entry has left, or -1 when it does not expire.
# Fails when there is no such entry.
function cache.memory.ttl {
	__verify_nr_args "$#" 2 cache.memory.ttl
	local now expires
	cache._verify_exists "$1" || return 1
	cache.memory.has "$1" "$2" || return 1
	expires="${CRUCIBLE_CACHE_EXPIRES["$1|$2"]:-}"
	if [ -z "$expires" ]; then
		echo "-1"
	else
		cache._now now
		echo $((expires - now))
	fi
}

# Prints how often get found an entry and how often it did not
function cache.memory.stats {
	__verify_nr_args "$#" 1 cache.memory.stats
	cache._verify_exists "$1" || return 1
	echo "hits=${CRUCIBLE_CACHE_STATS["$1|hits"]:-0} misses=${CRUCIBLE_CACHE_STATS["$1|misses"]:-0}"
}

# Gets the value of the entry into the variable that is named, and when there
# is no such entry asks the function for it: that is called with the key and
# prints the value. That value is stored, with the ttl when it is given, and
# put in the variable. When the function fails nothing is stored and its
# status is the result. Trailing line breaks of the value are lost.
#
# This works through a variable and not through stdout because a cache cannot
# be filled from $(...): the subshell would forget what it stored.
# Usage: cache.memory.get_or_compute_into <variable> <name> <key> <function> [ttl]
function cache.memory.get_or_compute_into {
	if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
		logging.error "cache.memory.get_or_compute_into: usage is cache.memory.get_or_compute_into <VARIABLE> <NAME> <KEY> <FUNCTION> [TTL]"
		return 1
	fi
	local _cache_value _cache_status
	cache._verify_exists "$2" || return 1
	if cache.memory.has "$2" "$3"; then
		local -n _cache_values="$2"
		cache._count "$2" hits
		printf -v "$1" '%s' "${_cache_values["$3"]}"
		return 0
	fi
	if ! declare -F "$4" >/dev/null; then
		logging.error "$4 is not a function"
		return 1
	fi
	cache._count "$2" misses
	_cache_value="$("$4" "$3")"
	_cache_status=$?
	if [ "$_cache_status" -ne 0 ]; then
		return "$_cache_status"
	fi
	cache.memory.put "$2" "$3" "$_cache_value" "${5:-}" || return 1
	printf -v "$1" '%s' "$_cache_value"
}

# The same, but prints the value. Call it directly: in $(...) the value is
# printed but the entry is not stored.
# Usage: cache.memory.get_or_compute <name> <key> <function> [ttl]
function cache.memory.get_or_compute {
	if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
		logging.error "cache.memory.get_or_compute: usage is cache.memory.get_or_compute <NAME> <KEY> <FUNCTION> [TTL]"
		return 1
	fi
	local _cache_result
	cache.memory.get_or_compute_into _cache_result "$@" || return
	printf '%s\n' "$_cache_result"
}
