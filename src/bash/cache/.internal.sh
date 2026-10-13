#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging

# What the caches know about themselves. The entries of a cache named
# "sessions" live in an associative array that is called sessions.
# name -> seconds an entry lives when it is stored without ttl, 0 is forever
declare -gA CRUCIBLE_CACHE_TTL
# "name|key" -> the second since the epoch from which on the entry is gone
# shellcheck disable=SC2034
declare -gA CRUCIBLE_CACHE_EXPIRES
# "name|hits" and "name|misses" -> how often get found, or did not find, an entry
declare -gA CRUCIBLE_CACHE_STATS
# name -> the file of a file cache
# shellcheck disable=SC2034
declare -gA CRUCIBLE_CACHE_FILES

# Stores the seconds since the epoch in the variable that is named. Setting
# CRUCIBLE_CACHE_NOW overrides the clock, which is what the tests do.
function cache._now {
	if [ -n "${CRUCIBLE_CACHE_NOW:-}" ]; then
		printf -v "$1" '%s' "$CRUCIBLE_CACHE_NOW"
	else
		printf -v "$1" '%(%s)T' -1
	fi
}

function cache._verify_name {
	if ! [[ "$1" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]] || [[ "$1" == CRUCIBLE_* || "$1" == _cache_* ]]; then
		logging.error "Not a valid name for a cache: $1 (letters, digits and underscores, starting with a letter)"
		return 1
	fi
}

function cache._verify_exists {
	if [ -z "${CRUCIBLE_CACHE_TTL[$1]+_}" ]; then
		logging.error "There is no cache named $1"
		return 1
	fi
}

function cache._verify_seconds {
	if ! [[ "$1" =~ ^[0-9]+$ ]]; then
		logging.error "Not a number of seconds: $1"
		return 1
	fi
}

function cache._verify_key {
	if [ -z "$1" ]; then
		logging.error "A key cannot be empty"
		return 1
	fi
}

function cache._count {
	CRUCIBLE_CACHE_STATS["$1|$2"]=$((${CRUCIBLE_CACHE_STATS["$1|$2"]:-0} + 1))
}

# Escapes what the file format uses to structure itself, and nothing else:
# the separator, line breaks and the escape character. The result goes in the
# variable that is named; the local here has an odd name so that a caller can
# use any variable, a local of the same name would swallow the result.
function cache._encode {
	local _cache_text
	_cache_text="$2"
	_cache_text="${_cache_text//%/%25}"
	_cache_text="${_cache_text//|/%7C}"
	_cache_text="${_cache_text//$'\n'/%0A}"
	_cache_text="${_cache_text//$'\r'/%0D}"
	printf -v "$1" '%s' "$_cache_text"
}

function cache._decode {
	local _cache_text
	_cache_text="$2"
	_cache_text="${_cache_text//%0D/$'\r'}"
	_cache_text="${_cache_text//%0A/$'\n'}"
	_cache_text="${_cache_text//%7C/|}"
	_cache_text="${_cache_text//%25/%}"
	printf -v "$1" '%s' "$_cache_text"
}
