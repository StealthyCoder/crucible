#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

# The variables with the result of a request are for the caller, not for this file
# shellcheck disable=SC2034
require core/.internal
require logging/logging
require io/network/tcp

# An HTTP client in bash: the request goes over /dev/tcp and the response is
# read with read, there is no curl or wget behind it.
#
# Only http:// works. Bash cannot do TLS, and calling curl for https:// would
# be the dependency crucible does not want. Bodies are text: bash cannot hold
# NUL bytes, so those are dropped from what is received.
#
# The result of a request is in these variables, and not on stdout, because
# a request made inside $(...) would keep them to itself:
#   CRUCIBLE_HTTP_STATUS   the status code, like 200
#   CRUCIBLE_HTTP_REASON   the text after it, like OK
#   CRUCIBLE_HTTP_BODY     the body
#   CRUCIBLE_HTTP_HEADERS  an associative array of the headers of the
#                          response, with the names in lower case
#   CRUCIBLE_HTTP_URL      the url that was answered, after redirects
# http.get and the others print the body as well, use that when the rest is
# of no interest.
#
# Settings, as environment variables:
#   CRUCIBLE_HTTP_TIMEOUT        seconds the server may stay silent, 30
#   CRUCIBLE_HTTP_MAX_REDIRECTS  redirects to follow, 5, and 0 follows none
#   CRUCIBLE_HTTP_USER_AGENT     crucible
#
# The status of a request is 0 for everything below 400, 22 for a status of
# 400 or higher (the body and variables are there), and 1 when there was no
# usable answer.
declare -g CRUCIBLE_HTTP_STATUS CRUCIBLE_HTTP_REASON CRUCIBLE_HTTP_BODY CRUCIBLE_HTTP_URL
declare -gA CRUCIBLE_HTTP_HEADERS

# Puts the scheme, the host, the port and the target (path and query) of an
# http url in the array that is named. This does not run in a subshell, so
# the reason a url is refused is not lost in the output of one.
# Usage: http._parse_url <url> <array>
function http._parse_url {
	local url scheme host port target
	local -n _http_parts="$2"
	url="$1"
	if [[ "$url" == *[[:space:][:cntrl:]]* ]]; then
		logging.error "A url cannot contain spaces or control characters: $url"
		return 1
	fi
	if ! [[ "$url" =~ ^([A-Za-z][A-Za-z0-9+.-]*)://([^/?#]*)([^#]*)(#.*)?$ ]]; then
		logging.error "Not a url: $url"
		return 1
	fi
	scheme="${BASH_REMATCH[1],,}"
	host="${BASH_REMATCH[2]}"
	target="${BASH_REMATCH[3]}"
	case "$scheme" in
	http) ;;
	https)
		logging.error "https is not supported, bash cannot do TLS: $url"
		return 1
		;;
	*)
		logging.error "Only http urls are supported, not $scheme"
		return 1
		;;
	esac
	if [[ "$host" == *@* ]]; then
		logging.error "A user name and password in the url are not supported, send an Authorization header: $url"
		return 1
	fi
	if [[ "$host" =~ ^(.+):([0-9]+)$ ]]; then
		port="${BASH_REMATCH[2]}"
		host="${BASH_REMATCH[1]}"
	else
		port=80
	fi
	if ! network.verify_host "$host"; then
		logging.error "Invalid host in url: $url"
		return 1
	fi
	if ! network.verify_port "$port"; then
		logging.error "Invalid port in url: $url"
		return 1
	fi
	if [ -z "$target" ]; then
		target="/"
	elif [[ "$target" == \?* ]]; then
		target="/$target"
	fi
	_http_parts=("$scheme" "$host" "$port" "$target")
}

# Prints the scheme, the host, the port and the target (path and query) of an
# http url, one to a line.
function http.parse_url {
	__verify_nr_args "$#" 1 http.parse_url
	local -a parts
	http._parse_url "$1" parts || return 1
	printf '%s\n' "${parts[@]}"
}

# Percent encodes everything but letters, digits and - _ . ~
function http.url_encode {
	__verify_nr_args "$#" 1 http.url_encode
	local LC_ALL=C
	local text char result i
	text="$1"
	result=""
	for ((i = 0; i < ${#text}; i++)); do
		char="${text:i:1}"
		case "$char" in
		[A-Za-z0-9._~-]) result+="$char" ;;
		*)
			printf -v char '%%%02X' "'$char"
			result+="$char"
			;;
		esac
	done
	printf '%s\n' "$result"
}

# Turns %XX back into the character. A + stays a +. %00 is left alone, bash cannot hold a NUL.
function http.url_decode {
	__verify_nr_args "$#" 1 http.url_decode
	local LC_ALL=C
	local text result hex
	text="$1"
	result=""
	while [[ "$text" =~ ^([^%]*)%([0-9a-fA-F]{2})(.*)$ ]]; do
		result+="${BASH_REMATCH[1]}"
		hex="${BASH_REMATCH[2]}"
		text="${BASH_REMATCH[3]}"
		if [ "${hex^^}" = "00" ]; then
			result+="%00"
		else
			printf -v hex '%b' "\\x$hex"
			result+="$hex"
		fi
	done
	printf '%s\n' "$result$text"
}

# Makes the body of a form: http.form_encode name Ada city "New York" gives
# name=Ada&city=New%20York
function http.form_encode {
	if [ "$#" -eq 0 ] || [ $(("$#" % 2)) -ne 0 ]; then
		logging.error "http.form_encode: usage is http.form_encode <NAME> <VALUE> [<NAME> <VALUE>]..."
		return 1
	fi
	local result
	result=""
	while [ "$#" -gt 0 ]; do
		result+="$(http.url_encode "$1")=$(http.url_encode "$2")&"
		shift 2
	done
	printf '%s\n' "${result%&}"
}

# Prints a header of the last response, the name does not have to be in lower case
function http.header {
	__verify_nr_args "$#" 1 http.header
	local name
	name="${1,,}"
	[ -n "${CRUCIBLE_HTTP_HEADERS[$name]+_}" ] || return 1
	printf '%s\n' "${CRUCIBLE_HTTP_HEADERS[$name]}"
}

function http.status {
	printf '%s\n' "$CRUCIBLE_HTTP_STATUS"
}

# Turns the Location of a redirect into a full url
# Usage: http._resolve <url that was requested> <location>
function http._resolve {
	local url location authority path
	url="$1"
	location="$2"
	if [[ "$location" =~ ^[A-Za-z][A-Za-z0-9+.-]*:// ]]; then
		printf '%s\n' "$location"
		return
	fi
	[[ "$url" =~ ^([A-Za-z][A-Za-z0-9+.-]*://[^/?#]*)([^?#]*) ]]
	authority="${BASH_REMATCH[1]}"
	path="${BASH_REMATCH[2]}"
	if [[ "$location" == //* ]]; then
		printf 'http:%s\n' "$location"
	elif [[ "$location" == /* ]]; then
		printf '%s%s\n' "$authority" "$location"
	else
		path="${path%/*}/"
		printf '%s%s%s\n' "$authority" "$path" "$location"
	fi
}

# Reads a line of the response without its line ending
# Usage: http._read_line <fd> <variable>
function http._read_line {
	local _http_line _http_status
	local -a _http_timeout
	_http_timeout=(-t "${CRUCIBLE_HTTP_TIMEOUT:-30}")
	IFS= read -r "${_http_timeout[@]}" -u "$1" _http_line
	_http_status=$?
	if [ "$_http_status" -ne 0 ]; then
		if [ "$_http_status" -gt 128 ]; then
			logging.error "The server did not answer within ${CRUCIBLE_HTTP_TIMEOUT:-30} seconds"
		else
			logging.error "The server closed the connection before the response was complete"
		fi
		return 1
	fi
	printf -v "$2" '%s' "${_http_line%$'\r'}"
}

# Reads exactly <count> characters, or fewer when the server stops sending
# Usage: http._read_chars <fd> <count> <variable>
function http._read_chars {
	local _http_chars _http_status
	IFS= read -r -t "${CRUCIBLE_HTTP_TIMEOUT:-30}" -N "$2" -u "$1" _http_chars
	_http_status=$?
	if [ "$_http_status" -gt 128 ]; then
		logging.error "The server did not answer within ${CRUCIBLE_HTTP_TIMEOUT:-30} seconds"
		return 1
	fi
	printf -v "$3" '%s' "$_http_chars"
}

# Does one request, without following redirects, and fills the variables
# Usage: http._exchange <method> <url> <body> [header]...
function http._exchange {
	local LC_ALL=C
	local method url body fd scheme host port target hostport request header name value
	local line code reason size chunk n expected
	local -A given
	local -a parts
	method="$1"
	url="$2"
	body="$3"
	shift 3
	http._parse_url "$url" parts || return 1
	scheme="${parts[0]}"
	host="${parts[1]}"
	port="${parts[2]}"
	target="${parts[3]}"
	hostport="$host"
	if [ "$port" != "80" ]; then
		hostport="$host:$port"
	fi

	request="$method $target HTTP/1.1"$'\r\n'
	for header in "$@"; do
		if [[ "$header" == *[$'\r\n']* ]] || ! [[ "$header" =~ ^[A-Za-z0-9!#\$%\&\'*+.^_\`\|~-]+:.*$ ]]; then
			logging.error "Not a valid header: $header"
			return 1
		fi
		name="${header%%:*}"
		given["${name,,}"]=1
		request+="$header"$'\r\n'
	done
	[ -n "${given[host]+_}" ] || request+="Host: $hostport"$'\r\n'
	[ -n "${given["user-agent"]+_}" ] || request+="User-Agent: ${CRUCIBLE_HTTP_USER_AGENT:-crucible}"$'\r\n'
	[ -n "${given[accept]+_}" ] || request+="Accept: */*"$'\r\n'
	[ -n "${given[connection]+_}" ] || request+="Connection: close"$'\r\n'
	if [ -n "$body" ] || [[ "$method" == POST || "$method" == PUT || "$method" == PATCH ]]; then
		[ -n "${given["content-length"]+_}" ] || request+="Content-Length: ${#body}"$'\r\n'
		if [ -n "$body" ] && [ -z "${given["content-type"]+_}" ]; then
			request+="Content-Type: application/x-www-form-urlencoded"$'\r\n'
		fi
	fi
	request+=$'\r\n'

	CRUCIBLE_HTTP_STATUS=""
	CRUCIBLE_HTTP_REASON=""
	CRUCIBLE_HTTP_BODY=""
	CRUCIBLE_HTTP_HEADERS=()
	CRUCIBLE_HTTP_URL="$url"

	network._connect tcp "$host" "$port" fd || return 1
	printf '%s%s' "$request" "$body" >&"$fd"

	# Informational responses (like 100 Continue) come before the real one
	while :; do
		http._read_line "$fd" line || {
			network._close "$fd"
			return 1
		}
		if ! [[ "$line" =~ ^HTTP/1\.[01]\ ([0-9]{3})(\ (.*))?$ ]]; then
			logging.error "Not an HTTP response: $line"
			network._close "$fd"
			return 1
		fi
		code="${BASH_REMATCH[1]}"
		reason="${BASH_REMATCH[3]}"
		CRUCIBLE_HTTP_HEADERS=()
		while :; do
			http._read_line "$fd" line || {
				network._close "$fd"
				return 1
			}
			[ -n "$line" ] || break
			if [[ "$line" =~ ^([^:]+):[[:space:]]*(.*)$ ]]; then
				name="${BASH_REMATCH[1],,}"
				value="${BASH_REMATCH[2]}"
				value="${value%"${value##*[![:space:]]}"}"
				if [ -n "${CRUCIBLE_HTTP_HEADERS[$name]+_}" ]; then
					CRUCIBLE_HTTP_HEADERS["$name"]+=", $value"
				else
					CRUCIBLE_HTTP_HEADERS["$name"]="$value"
				fi
			fi
		done
		[[ "$code" == 1* && "$code" != 101 ]] || break
	done
	CRUCIBLE_HTTP_STATUS="$code"
	CRUCIBLE_HTTP_REASON="$reason"

	if [[ "$method" == HEAD || "$code" == 204 || "$code" == 304 || "$code" == 1* ]]; then
		network._close "$fd"
		return 0
	fi

	if [[ "${CRUCIBLE_HTTP_HEADERS["transfer-encoding"]:-}" == *[Cc][Hh][Uu][Nn][Kk][Ee][Dd]* ]]; then
		while :; do
			http._read_line "$fd" size || {
				network._close "$fd"
				return 1
			}
			size="${size%%;*}"
			size="${size//[[:space:]]/}"
			if ! [[ "$size" =~ ^[0-9a-fA-F]+$ ]]; then
				logging.error "Not a chunk size: $size"
				network._close "$fd"
				return 1
			fi
			n=$((16#$size))
			if [ "$n" -eq 0 ]; then
				# Trailers, up to the empty line
				while http._read_line "$fd" line 2>/dev/null && [ -n "$line" ]; do :; done
				break
			fi
			http._read_chars "$fd" "$n" chunk || {
				network._close "$fd"
				return 1
			}
			if [ "${#chunk}" -lt "$n" ]; then
				logging.warning "A chunk of $n bytes arrived with ${#chunk}, bash drops NUL bytes"
			fi
			CRUCIBLE_HTTP_BODY+="$chunk"
			http._read_line "$fd" line || {
				network._close "$fd"
				return 1
			}
		done
	elif [ -n "${CRUCIBLE_HTTP_HEADERS["content-length"]+_}" ]; then
		expected="${CRUCIBLE_HTTP_HEADERS["content-length"]}"
		if ! [[ "$expected" =~ ^[0-9]+$ ]]; then
			logging.error "Not a content length: $expected"
			network._close "$fd"
			return 1
		fi
		if [ "$expected" -gt 0 ]; then
			http._read_chars "$fd" "$expected" CRUCIBLE_HTTP_BODY || {
				network._close "$fd"
				return 1
			}
		fi
		if [ "${#CRUCIBLE_HTTP_BODY}" -lt "$expected" ]; then
			logging.warning "The server announced $expected bytes and ${#CRUCIBLE_HTTP_BODY} arrived, bash drops NUL bytes"
		fi
	else
		# No length: the body ends when the server closes the connection
		while IFS= read -r -t "${CRUCIBLE_HTTP_TIMEOUT:-30}" -N 65536 -u "$fd" chunk; do
			CRUCIBLE_HTTP_BODY+="$chunk"
		done
		CRUCIBLE_HTTP_BODY+="$chunk"
	fi
	network._close "$fd"
}

# Makes a request and follows redirects.
# Usage: http.request <method> <url> <body> [header]...
# The body is empty for GET, HEAD and DELETE. A header is written Name: value
function http.request {
	if [ "$#" -lt 3 ]; then
		logging.error "http.request: usage is http.request <METHOD> <URL> <BODY> [HEADER]..."
		return 1
	fi
	local method url body location redirects max_redirects
	local -a headers
	method="${1^^}"
	url="$2"
	body="$3"
	shift 3
	headers=("$@")
	if ! [[ "$method" =~ ^[A-Z]+$ ]]; then
		logging.error "Not a method: $method"
		return 1
	fi
	max_redirects="${CRUCIBLE_HTTP_MAX_REDIRECTS:-5}"
	redirects=0
	while :; do
		http._exchange "$method" "$url" "$body" "${headers[@]}" || return 1
		case "$CRUCIBLE_HTTP_STATUS" in
		301 | 302 | 303 | 307 | 308) ;;
		*) break ;;
		esac
		location="${CRUCIBLE_HTTP_HEADERS[location]:-}"
		if [ "$max_redirects" -eq 0 ] || [ -z "$location" ]; then
			break
		fi
		redirects=$((redirects + 1))
		if [ "$redirects" -gt "$max_redirects" ]; then
			logging.error "More than $max_redirects redirects, the last one went to $location"
			return 1
		fi
		url="$(http._resolve "$url" "$location")"
		# What was posted is not posted again after these, as browsers do
		case "$CRUCIBLE_HTTP_STATUS" in
		301 | 302 | 303)
			if [ "$method" != "HEAD" ]; then
				method="GET"
				body=""
			fi
			;;
		esac
	done
	CRUCIBLE_HTTP_URL="$url"
	if [ "$CRUCIBLE_HTTP_STATUS" -ge 400 ]; then
		return 22
	fi
}

# Prints the body of the response of the last request, as it is
function http._print_body {
	printf '%s' "$CRUCIBLE_HTTP_BODY"
}

# The methods below make the request and print the body.
# Usage: http.get <url> [header]...
function http.get {
	[ "$#" -ge 1 ] || {
		logging.error "http.get: usage is http.get <URL> [HEADER]..."
		return 1
	}
	local url status
	url="$1"
	shift
	http.request GET "$url" "" "$@"
	status=$?
	http._print_body
	return "$status"
}

function http.head {
	[ "$#" -ge 1 ] || {
		logging.error "http.head: usage is http.head <URL> [HEADER]..."
		return 1
	}
	local url
	url="$1"
	shift
	http.request HEAD "$url" "" "$@"
}

function http.delete {
	[ "$#" -ge 1 ] || {
		logging.error "http.delete: usage is http.delete <URL> [HEADER]..."
		return 1
	}
	local url status
	url="$1"
	shift
	http.request DELETE "$url" "" "$@"
	status=$?
	http._print_body
	return "$status"
}

# Usage: http.post <url> <body> [header]...
function http.post {
	[ "$#" -ge 2 ] || {
		logging.error "http.post: usage is http.post <URL> <BODY> [HEADER]..."
		return 1
	}
	local url body status
	url="$1"
	body="$2"
	shift 2
	http.request POST "$url" "$body" "$@"
	status=$?
	http._print_body
	return "$status"
}

function http.put {
	[ "$#" -ge 2 ] || {
		logging.error "http.put: usage is http.put <URL> <BODY> [HEADER]..."
		return 1
	}
	local url body status
	url="$1"
	body="$2"
	shift 2
	http.request PUT "$url" "$body" "$@"
	status=$?
	http._print_body
	return "$status"
}

function http.patch {
	[ "$#" -ge 2 ] || {
		logging.error "http.patch: usage is http.patch <URL> <BODY> [HEADER]..."
		return 1
	}
	local url body status
	url="$1"
	body="$2"
	shift 2
	http.request PATCH "$url" "$body" "$@"
	status=$?
	http._print_body
	return "$status"
}
