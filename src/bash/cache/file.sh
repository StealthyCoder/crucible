#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.3.0
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1791901074
### CRUCIBLE META DATA ###

# A nameref to the array of the cache is used as an array, shellcheck sees a string
# shellcheck disable=SC2178
require core/.internal
require logging/logging
require cache/.internal
require cache/memory

# A cache that is kept in a file, so that it outlives the script and can be
# shared by scripts. It is the memory cache with the same entries and expiry,
# every read starts from what is in the file and every change is written back.
# Changes are not atomic and there is no locking: scripts that write at the
# same moment can lose each other's changes.
#
# The file has one line per entry, expiry|key|value, with the separator,
# line breaks and % escaped. It is read as data and never run as code.
# Usage: cache.file.create <name> <file> [default ttl in seconds, 0 is forever]
function cache.file.create {
	if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
		logging.error "cache.file.create: usage is cache.file.create <NAME> <FILE> [TTL]"
		return 1
	fi
	if [ -z "$2" ]; then
		logging.error "A file cache needs a file"
		return 1
	fi
	cache.memory.create "$1" "${3:-0}" || return 1
	CRUCIBLE_CACHE_FILES["$1"]="$2"
	cache.file.load "$1"
}

function cache.file._verify {
	cache._verify_exists "$1" || return 1
	if [ -z "${CRUCIBLE_CACHE_FILES[$1]+_}" ]; then
		logging.error "$1 is not a file cache"
		return 1
	fi
}

# Replaces what is in memory by what is in the file, without the expired entries
function cache.file.load {
	__verify_nr_args "$#" 1 cache.file.load
	local expires encoded_key encoded_value key value now
	cache.file._verify "$1" || return 1
	local -n _cache_values="$1"
	cache.memory.clear "$1"
	[ -r "${CRUCIBLE_CACHE_FILES[$1]}" ] || return 0
	cache._now now
	while IFS='|' read -r expires encoded_key encoded_value || [ -n "$expires" ]; do
		# Anything that is not an entry, like the first line, is skipped
		[[ "$expires" =~ ^[0-9]+$ ]] || continue
		[ -n "$encoded_key" ] || continue
		if [ "$expires" -gt 0 ] && [ "$now" -ge "$expires" ]; then
			continue
		fi
		cache._decode key "$encoded_key"
		cache._decode value "$encoded_value"
		_cache_values["$key"]="$value"
		if [ "$expires" -gt 0 ]; then
			CRUCIBLE_CACHE_EXPIRES["$1|$key"]="$expires"
		fi
	done <"${CRUCIBLE_CACHE_FILES[$1]}"
}

# Writes what is in memory to the file, without the expired entries. A new
# file can only be read by its owner, a cache can hold secrets.
function cache.file.save {
	__verify_nr_args "$#" 1 cache.file.save
	local key encoded_key encoded_value
	cache.file._verify "$1" || return 1
	local -n _cache_values="$1"
	cache.memory.evict_expired "$1" >/dev/null
	(
		umask 077
		{
			printf '# crucible cache 1\n'
			for key in "${!_cache_values[@]}"; do
				cache._encode encoded_key "$key"
				cache._encode encoded_value "${_cache_values[$key]}"
				printf '%s|%s|%s\n' "${CRUCIBLE_CACHE_EXPIRES["$1|$key"]:-0}" "$encoded_key" "$encoded_value"
			done
		} >"${CRUCIBLE_CACHE_FILES[$1]}"
	)
}

# Usage: cache.file.put <name> <key> <value> [ttl in seconds, 0 is forever]
function cache.file.put {
	if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
		logging.error "cache.file.put: usage is cache.file.put <NAME> <KEY> <VALUE> [TTL]"
		return 1
	fi
	cache.file.load "$1" || return 1
	cache.memory.put "$@" || return 1
	cache.file.save "$1"
}

function cache.file.get {
	__verify_nr_args "$#" 2 cache.file.get
	cache.file.load "$1" || return 1
	cache.memory.get "$1" "$2"
}

function cache.file.has {
	__verify_nr_args "$#" 2 cache.file.has
	cache.file.load "$1" || return 1
	cache.memory.has "$1" "$2"
}

function cache.file.remove {
	__verify_nr_args "$#" 2 cache.file.remove
	cache.file.load "$1" || return 1
	cache.memory.remove "$1" "$2"
	cache.file.save "$1"
}

function cache.file.clear {
	__verify_nr_args "$#" 1 cache.file.clear
	cache.file._verify "$1" || return 1
	cache.memory.clear "$1"
	cache.file.save "$1"
}

function cache.file.keys {
	__verify_nr_args "$#" 1 cache.file.keys
	cache.file.load "$1" || return 1
	cache.memory.keys "$1"
}

function cache.file.size {
	__verify_nr_args "$#" 1 cache.file.size
	cache.file.load "$1" || return 1
	cache.memory.size "$1"
}

function cache.file.ttl {
	__verify_nr_args "$#" 2 cache.file.ttl
	cache.file.load "$1" || return 1
	cache.memory.ttl "$1" "$2"
}

# The same as cache.memory.get_or_compute_into, the entry is saved when it was computed
# Usage: cache.file.get_or_compute_into <variable> <name> <key> <function> [ttl]
function cache.file.get_or_compute_into {
	if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
		logging.error "cache.file.get_or_compute_into: usage is cache.file.get_or_compute_into <VARIABLE> <NAME> <KEY> <FUNCTION> [TTL]"
		return 1
	fi
	local _cache_misses
	cache.file.load "$2" || return 1
	_cache_misses="${CRUCIBLE_CACHE_STATS["$2|misses"]:-0}"
	cache.memory.get_or_compute_into "$@" || return
	# A new miss means the function ran and the entry is new
	if [ "${CRUCIBLE_CACHE_STATS["$2|misses"]:-0}" != "$_cache_misses" ]; then
		cache.file.save "$2"
	fi
}

function cache.file.get_or_compute {
	if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
		logging.error "cache.file.get_or_compute: usage is cache.file.get_or_compute <NAME> <KEY> <FUNCTION> [TTL]"
		return 1
	fi
	local _cache_result
	cache.file.get_or_compute_into _cache_result "$@" || return
	printf '%s\n' "$_cache_result"
}
