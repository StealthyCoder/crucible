#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

# The variables with the result of a query are for the caller, not for this file
# shellcheck disable=SC2034

require core/.internal
require logging/logging
require io/network/tcp

# A DNS client in bash. The messages are built and read by this file, there is
# no dig or host behind it.
#
# It asks over TCP (RFC 1035 section 4.2.2), the same messages as over UDP with
# the length in front. That is not a taste: an answer is binary and full of NUL
# bytes, bash can only read those exactly from a stream and loses the end of a
# datagram, see __read_bytes_hex.
#
# The result of a query is in these variables, and not on stdout, because a
# query made inside $(...) would keep them to itself:
#   CRUCIBLE_DNS_RESPONSE      an associative array: id, qr, opcode, aa, tc,
#                              rd, ra, rcode, rcode_name, qdcount, ancount,
#                              nscount, arcount, qname, qtype and qclass
#   CRUCIBLE_DNS_ANSWERS       an array of records, one "name ttl class type rdata"
#   CRUCIBLE_DNS_AUTHORITIES   the same for the authority section
#   CRUCIBLE_DNS_ADDITIONALS   the same for the additional section
#
# The server is the argument, CRUCIBLE_DNS_SERVER, or the first IPv4
# nameserver of /etc/resolv.conf (CRUCIBLE_DNS_RESOLV_CONF names another file).
# CRUCIBLE_DNS_TIMEOUT is the seconds the server may be silent, 5, and
# CRUCIBLE_DNS_PORT is the port of the server, 53.
#
# Types: A NS CNAME SOA PTR MX TXT AAAA SRV. Others come back as
# "\# <length> <hex>" (RFC 3597). Names with a dot inside a label cannot be asked for.
declare -gA CRUCIBLE_DNS_RESPONSE
declare -ga CRUCIBLE_DNS_ANSWERS CRUCIBLE_DNS_AUTHORITIES CRUCIBLE_DNS_ADDITIONALS
declare -gA CRUCIBLE_DNS_TYPES=([A]=1 [NS]=2 [CNAME]=5 [SOA]=6 [PTR]=12 [MX]=15 [TXT]=16 [AAAA]=28 [SRV]=33 [ANY]=255)
declare -gA CRUCIBLE_DNS_TYPE_NAMES=([1]=A [2]=NS [5]=CNAME [6]=SOA [12]=PTR [15]=MX [16]=TXT [28]=AAAA [33]=SRV [255]=ANY)

# The helpers below hand their result back in the variables _dns_type,
# _dns_encoded, _dns_name, _dns_next and _dns_text. Naming the variable that
# the caller wants would not work: a helper that has a local of that name
# would fill its own local and the caller would get nothing.
#
# Sets _dns_type to the number of a type, given as a name or a number
# Usage: dns._type_number <type>
function dns._type_number {
	local type
	type="${1^^}"
	if [ -n "${CRUCIBLE_DNS_TYPES[$type]+_}" ]; then
		_dns_type="${CRUCIBLE_DNS_TYPES[$type]}"
	elif [[ "$type" =~ ^[0-9]+$ ]] && [ "$type" -ge 1 ] && [ "$type" -le 65535 ]; then
		_dns_type="$type"
	else
		logging.error "Not a known record type: $1"
		return 1
	fi
}

# Sets _dns_encoded to a name as the hexadecimal digits of a DNS name
# Usage: dns._encode_name <name>
function dns._encode_name {
	local LC_ALL=C
	local name label hex byte i
	local -a labels
	name="${1%.}"
	hex=""
	if [ -n "$name" ]; then
		if [ "${#name}" -gt 253 ]; then
			logging.error "A name has at most 253 characters: $1"
			return 1
		fi
		IFS=. read -r -a labels <<<"$name"
		# One trailing dot was taken off, one more leaves an empty last label that read drops
		if [[ "$name" == *. ]]; then
			logging.error "Not a valid name: $1"
			return 1
		fi
		for label in "${labels[@]}"; do
			if ! [[ "$label" =~ ^[A-Za-z0-9_-]{1,63}$ ]]; then
				logging.error "Not a valid name, a label is empty, too long or has unusual characters: $1"
				return 1
			fi
			printf -v byte '%02X' "${#label}"
			hex+="$byte"
			for ((i = 0; i < ${#label}; i++)); do
				printf -v byte '%02X' "'${label:i:1}"
				hex+="$byte"
			done
		done
	fi
	_dns_encoded="${hex}00"
}

# Prints the hexadecimal digits of a query, without the length that TCP puts in front.
# The id is a number from 0 to 65535, CRUCIBLE_DNS_QUERY_ID or a random one.
# Usage: dns.build_query <name> [type] [id]
function dns.build_query {
	if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
		logging.error "dns.build_query: usage is dns.build_query <NAME> [TYPE] [ID]"
		return 1
	fi
	local id random hex_id
	dns._type_number "${2:-A}" || return 1
	dns._encode_name "$1" || return 1
	id="${3:-${CRUCIBLE_DNS_QUERY_ID:-}}"
	if [ -z "$id" ]; then
		# Two random bytes, RANDOM is only a fallback
		exec {random}</dev/urandom
		__read_bytes_hex "$random" 2
		hex_id="$__READ_HEX"
		__forget_read_buffer "$random"
		exec {random}<&-
		if [ "${#hex_id}" -eq 4 ]; then
			id=$((16#$hex_id))
		else
			id=$((RANDOM * 2 + RANDOM % 2))
		fi
	fi
	if ! [[ "$id" =~ ^[0-9]+$ ]] || [ "$id" -gt 65535 ]; then
		logging.error "Not a query id: $id"
		return 1
	fi
	# The id, the flags with only "recursion desired", one question and nothing else
	printf '%04X01000001000000000000%s%04X0001\n' "$id" "$_dns_encoded" "$_dns_type"
}

# Sets _dns_name to the name that starts at the byte offset, and _dns_next to the
# byte offset behind it. Compression pointers are followed, but not forever and
# not out of the message. Characters that would be confusing in a name are
# written as \. and \\ and \DDD (RFC 4343).
# Usage: dns._read_name <offset>
function dns._read_name {
	local LC_ALL=C
	local offset jumps next name label_length label byte char i text_length
	offset="$1"
	jumps=0
	next=-1
	name=""
	while :; do
		if ((offset >= dns_total)); then
			logging.error "The message ends in the middle of a name"
			return 1
		fi
		label_length=$((16#${dns_message:offset*2:2}))
		if ((label_length == 0)); then
			offset=$((offset + 1))
			break
		elif ((label_length >= 192)); then
			if ((offset + 2 > dns_total)); then
				logging.error "The message ends in the middle of a name"
				return 1
			fi
			if ((next < 0)); then
				next=$((offset + 2))
			fi
			jumps=$((jumps + 1))
			if ((jumps > 64)); then
				logging.error "A name points to itself"
				return 1
			fi
			offset=$((16#${dns_message:offset*2:4} & 16383))
			continue
		elif ((label_length >= 64)); then
			logging.error "A name uses a label type that does not exist"
			return 1
		fi
		offset=$((offset + 1))
		if ((offset + label_length > dns_total)); then
			logging.error "The message ends in the middle of a name"
			return 1
		fi
		label=""
		for ((i = 0; i < label_length; i++)); do
			byte=$((16#${dns_message:(offset + i)*2:2}))
			if ((byte == 46)); then
				label+='\.'
			elif ((byte == 92)); then
				label+='\\'
			elif ((byte > 32 && byte < 127)); then
				printf -v char "\\x${dns_message:(offset + i)*2:2}"
				label+="$char"
			else
				printf -v char '\\%03d' "$byte"
				label+="$char"
			fi
		done
		name+="$label."
		offset=$((offset + label_length))
		text_length=${#name}
		if ((text_length > 1000)); then
			logging.error "A name is too long"
			return 1
		fi
	done
	if ((next < 0)); then
		next=$offset
	fi
	_dns_name="${name:-.}"
	_dns_next="$next"
}

# Sets _dns_text to an IPv6 address from its 16 bytes at the offset the way RFC
# 5952 writes it: lower case, no leading zeros, and the longest run of zero groups as ::
# Usage: dns._format_ipv6 <offset>
function dns._format_ipv6 {
	local offset i group run_start run_length best_start best_length text
	local -a groups
	offset="$1"
	for ((i = 0; i < 8; i++)); do
		printf -v group '%x' $((16#${dns_message:(offset + i * 2)*2:4}))
		groups[i]="$group"
	done
	best_start=-1
	best_length=0
	run_start=-1
	run_length=0
	for ((i = 0; i < 8; i++)); do
		if [ "${groups[i]}" = "0" ]; then
			if ((run_start < 0)); then
				run_start=$i
				run_length=0
			fi
			run_length=$((run_length + 1))
			if ((run_length > best_length)); then
				best_start=$run_start
				best_length=$run_length
			fi
		else
			run_start=-1
		fi
	done
	if ((best_length < 2)); then
		best_start=-1
	fi
	text=""
	for ((i = 0; i < 8; i++)); do
		if ((best_start >= 0 && i == best_start)); then
			text+="::"
			i=$((i + best_length - 1))
			continue
		fi
		if [ -n "$text" ] && [ "${text: -1}" != ":" ]; then
			text+=":"
		fi
		text+="${groups[i]}"
	done
	_dns_text="$text"
}

# Sets _dns_text to the rdata of a record, as text
# Usage: dns._format_rdata <type number> <offset> <length>
function dns._format_rdata {
	local LC_ALL=C
	local type offset length text next target i byte string_length char value end
	type="$1"
	offset="$2"
	length="$3"
	text=""
	case "$type" in
	1)
		if ((length == 4)); then
			text="$((16#${dns_message:offset*2:2})).$((16#${dns_message:offset*2+2:2})).$((16#${dns_message:offset*2+4:2})).$((16#${dns_message:offset*2+6:2}))"
		fi
		;;
	28)
		if ((length == 16)); then
			dns._format_ipv6 "$offset"
			text="$_dns_text"
		fi
		;;
	2 | 5 | 12)
		dns._read_name "$offset" || return 1
		text="$_dns_name"
		;;
	15)
		if ((length >= 3)); then
			dns._read_name $((offset + 2)) || return 1
			text="$((16#${dns_message:offset*2:4})) $_dns_name"
		fi
		;;
	33)
		if ((length >= 7)); then
			dns._read_name $((offset + 6)) || return 1
			text="$((16#${dns_message:offset*2:4})) $((16#${dns_message:offset*2+4:4})) $((16#${dns_message:offset*2+8:4})) $_dns_name"
		fi
		;;
	6)
		dns._read_name "$offset" || return 1
		text="$_dns_name"
		dns._read_name "$_dns_next" || return 1
		text+=" $_dns_name"
		next="$_dns_next"
		if ((next + 20 > offset + length)); then
			logging.error "A SOA record that is too short"
			return 1
		fi
		for ((i = 0; i < 5; i++)); do
			text+=" $((16#${dns_message:(next + i * 4)*2:8}))"
		done
		;;
	16)
		i=0
		end=$length
		while ((i < end)); do
			string_length=$((16#${dns_message:(offset + i)*2:2}))
			i=$((i + 1))
			if ((i + string_length > end)); then
				logging.error "A TXT string that runs past its record"
				return 1
			fi
			value=""
			for ((next = 0; next < string_length; next++)); do
				byte=$((16#${dns_message:(offset + i + next)*2:2}))
				if ((byte == 34)); then
					value+='\"'
				elif ((byte == 92)); then
					value+='\\'
				elif ((byte >= 32 && byte < 127)); then
					printf -v char "\\x${dns_message:(offset + i + next)*2:2}"
					value+="$char"
				else
					printf -v char '\\%03d' "$byte"
					value+="$char"
				fi
			done
			text+="${text:+ }\"$value\""
			i=$((i + string_length))
		done
		;;
	esac
	if [ -z "$text" ]; then
		# Unknown type, or a known one with a length it should not have
		text="\\# $length ${dns_message:offset*2:length*2}"
	fi
	_dns_text="$text"
}

# Reads the records of a section into the array that is named, and moves the
# variable with the offset to the end of the section. The locals have odd
# names because they are references to variables of the caller.
# Usage: dns._read_section <count> <offset variable> <array>
function dns._read_section {
	local _dns_count _dns_pos _dns_type_code _dns_class _dns_ttl _dns_length _dns_class_name _dns_type_name _dns_record_name
	local -n _dns_offset_ref="$2"
	local -n _dns_records="$3"
	_dns_count="$1"
	_dns_pos="$_dns_offset_ref"
	_dns_records=()
	while ((_dns_count > 0)); do
		dns._read_name "$_dns_pos" || return 1
		_dns_record_name="$_dns_name"
		_dns_pos="$_dns_next"
		if ((_dns_pos + 10 > dns_total)); then
			logging.error "The message ends in the middle of a record"
			return 1
		fi
		_dns_type_code=$((16#${dns_message:_dns_pos*2:4}))
		_dns_class=$((16#${dns_message:_dns_pos*2+4:4}))
		_dns_ttl=$((16#${dns_message:_dns_pos*2+8:8}))
		_dns_length=$((16#${dns_message:_dns_pos*2+16:4}))
		_dns_pos=$((_dns_pos + 10))
		if ((_dns_pos + _dns_length > dns_total)); then
			logging.error "A record claims $_dns_length bytes and the message does not have them"
			return 1
		fi
		dns._format_rdata "$_dns_type_code" "$_dns_pos" "$_dns_length" || return 1
		case "$_dns_class" in
		1) _dns_class_name=IN ;;
		2) _dns_class_name=CS ;;
		3) _dns_class_name=CH ;;
		4) _dns_class_name=HS ;;
		*) _dns_class_name="CLASS$_dns_class" ;;
		esac
		_dns_type_name="${CRUCIBLE_DNS_TYPE_NAMES[$_dns_type_code]:-TYPE$_dns_type_code}"
		_dns_records+=("$_dns_record_name $_dns_ttl $_dns_class_name $_dns_type_name $_dns_text")
		_dns_pos=$((_dns_pos + _dns_length))
		_dns_count=$((_dns_count - 1))
	done
	_dns_offset_ref="$_dns_pos"
}

# Reads a message that is given as hexadecimal digits, without the TCP length, into the variables
# Usage: dns.parse_response <hex>
function dns.parse_response {
	__verify_nr_args "$#" 1 dns.parse_response
	local dns_message dns_total flags offset qtype qclass count
	local -A opcodes rcodes
	dns_message="${1^^}"
	CRUCIBLE_DNS_RESPONSE=()
	CRUCIBLE_DNS_ANSWERS=()
	CRUCIBLE_DNS_AUTHORITIES=()
	CRUCIBLE_DNS_ADDITIONALS=()
	if ! [[ "$dns_message" =~ ^([0-9A-F]{2})+$ ]]; then
		logging.error "A message is a string of hexadecimal digits"
		return 1
	fi
	dns_total=$((${#dns_message} / 2))
	if ((dns_total < 12)); then
		logging.error "A message is at least 12 bytes, this one has $dns_total"
		return 1
	fi
	opcodes=([0]=QUERY [1]=IQUERY [2]=STATUS [4]=NOTIFY [5]=UPDATE)
	rcodes=([0]=NOERROR [1]=FORMERR [2]=SERVFAIL [3]=NXDOMAIN [4]=NOTIMP [5]=REFUSED)
	flags=$((16#${dns_message:4:4}))
	CRUCIBLE_DNS_RESPONSE[id]=$((16#${dns_message:0:4}))
	CRUCIBLE_DNS_RESPONSE[qr]=$(((flags >> 15) & 1))
	CRUCIBLE_DNS_RESPONSE[opcode]="${opcodes[$(((flags >> 11) & 15))]:-OPCODE$(((flags >> 11) & 15))}"
	CRUCIBLE_DNS_RESPONSE[aa]=$(((flags >> 10) & 1))
	CRUCIBLE_DNS_RESPONSE[tc]=$(((flags >> 9) & 1))
	CRUCIBLE_DNS_RESPONSE[rd]=$(((flags >> 8) & 1))
	CRUCIBLE_DNS_RESPONSE[ra]=$(((flags >> 7) & 1))
	CRUCIBLE_DNS_RESPONSE[rcode]=$((flags & 15))
	CRUCIBLE_DNS_RESPONSE[rcode_name]="${rcodes[$((flags & 15))]:-RCODE$((flags & 15))}"
	CRUCIBLE_DNS_RESPONSE[qdcount]=$((16#${dns_message:8:4}))
	CRUCIBLE_DNS_RESPONSE[ancount]=$((16#${dns_message:12:4}))
	CRUCIBLE_DNS_RESPONSE[nscount]=$((16#${dns_message:16:4}))
	CRUCIBLE_DNS_RESPONSE[arcount]=$((16#${dns_message:20:4}))
	offset=12
	# Only the first question is kept, a resolver answers one
	count="${CRUCIBLE_DNS_RESPONSE[qdcount]}"
	while ((count > 0)); do
		dns._read_name "$offset" || return 1
		if ((_dns_next + 4 > dns_total)); then
			logging.error "The message ends in the middle of the question"
			return 1
		fi
		qtype=$((16#${dns_message:_dns_next*2:4}))
		qclass=$((16#${dns_message:_dns_next*2+4:4}))
		if [ -z "${CRUCIBLE_DNS_RESPONSE[qname]+_}" ]; then
			CRUCIBLE_DNS_RESPONSE[qname]="$_dns_name"
			CRUCIBLE_DNS_RESPONSE[qtype]="${CRUCIBLE_DNS_TYPE_NAMES[$qtype]:-TYPE$qtype}"
			CRUCIBLE_DNS_RESPONSE[qclass]="$([ "$qclass" -eq 1 ] && echo IN || echo "CLASS$qclass")"
		fi
		offset=$((_dns_next + 4))
		count=$((count - 1))
	done
	dns._read_section "${CRUCIBLE_DNS_RESPONSE[ancount]}" offset CRUCIBLE_DNS_ANSWERS || return 1
	dns._read_section "${CRUCIBLE_DNS_RESPONSE[nscount]}" offset CRUCIBLE_DNS_AUTHORITIES || return 1
	dns._read_section "${CRUCIBLE_DNS_RESPONSE[arcount]}" offset CRUCIBLE_DNS_ADDITIONALS || return 1
}

# Prints the server to ask: the argument, CRUCIBLE_DNS_SERVER, or the first
# IPv4 nameserver in resolv.conf
function dns._server {
	local keyword address rest
	if [ -n "${1:-}" ]; then
		printf '%s\n' "$1"
	elif [ -n "${CRUCIBLE_DNS_SERVER:-}" ]; then
		printf '%s\n' "$CRUCIBLE_DNS_SERVER"
	elif [ -r "${CRUCIBLE_DNS_RESOLV_CONF:-/etc/resolv.conf}" ]; then
		while read -r keyword address rest; do
			if [ "$keyword" = "nameserver" ] && [[ "$address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
				printf '%s\n' "$address"
				return 0
			fi
		done <"${CRUCIBLE_DNS_RESOLV_CONF:-/etc/resolv.conf}"
		logging.error "There is no IPv4 nameserver in ${CRUCIBLE_DNS_RESOLV_CONF:-/etc/resolv.conf}, give a server or set CRUCIBLE_DNS_SERVER"
		return 1
	else
		logging.error "There is no DNS server to ask, give a server or set CRUCIBLE_DNS_SERVER"
		return 1
	fi
}

# Asks a name server and puts the answer in the variables. The records of the
# answer section are printed, one "name ttl class type rdata" to a line.
# The status is 0 when there are answers, 1 when the question could not be
# asked or answered, 2 when the name does not exist (NXDOMAIN) and 3 when
# the name exists but has no record of this type.
# Usage: dns.query <name> [type] [server]
function dns.query {
	if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
		logging.error "dns.query: usage is dns.query <NAME> [TYPE] [SERVER]"
		return 1
	fi
	local query server fd timeout_seconds length body id record
	timeout_seconds="${CRUCIBLE_DNS_TIMEOUT:-5}"
	query="$(dns.build_query "$1" "${2:-A}")" || return 1
	server="$(dns._server "${3:-}")" || return 1
	network.verify_host "$server" || {
		logging.error "Not a valid DNS server: $server"
		return 1
	}
	id=$((16#${query:0:4}))
	network._connect tcp "$server" "${CRUCIBLE_DNS_PORT:-53}" fd || return 1
	network.tcp.send_hex "$fd" "$(printf '%04X' $((${#query} / 2)))$query"
	__read_bytes_hex "$fd" 2 "$timeout_seconds"
	length="$__READ_HEX"
	if [ "${#length}" -ne 4 ]; then
		logging.error "$server did not answer within $timeout_seconds seconds, or closed the connection"
		network._close "$fd"
		return 1
	fi
	length=$((16#$length))
	__read_bytes_hex "$fd" "$length" "$timeout_seconds"
	body="$__READ_HEX"
	network._close "$fd"
	if [ "${#body}" -ne $((length * 2)) ]; then
		logging.error "$server sent ${#body} of the $((length * 2)) digits that it announced"
		return 1
	fi
	dns.parse_response "$body" || return 1
	if [ "${CRUCIBLE_DNS_RESPONSE[id]}" -ne "$id" ] || [ "${CRUCIBLE_DNS_RESPONSE[qr]}" -ne 1 ]; then
		logging.error "$server answered a different question than the one that was asked"
		return 1
	fi
	case "${CRUCIBLE_DNS_RESPONSE[rcode_name]}" in
	NOERROR) ;;
	NXDOMAIN)
		logging.error "$1 does not exist"
		return 2
		;;
	*)
		logging.error "$server could not answer: ${CRUCIBLE_DNS_RESPONSE[rcode_name]}"
		return 1
		;;
	esac
	if [ "${#CRUCIBLE_DNS_ANSWERS[@]}" -eq 0 ]; then
		return 3
	fi
	for record in "${CRUCIBLE_DNS_ANSWERS[@]}"; do
		printf '%s\n' "$record"
	done
}

# Prints the data of the records of the type that was asked for, like the
# addresses of A. A name that is an alias (CNAME) is followed by the server.
# The status is that of dns.query.
# Usage: dns.resolve <name> [type] [server]
function dns.resolve {
	if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
		logging.error "dns.resolve: usage is dns.resolve <NAME> [TYPE] [SERVER]"
		return 1
	fi
	local type status name ttl class record_type data record
	type="${2:-A}"
	dns.query "$1" "$type" "${3:-}" >/dev/null
	status=$?
	if [ "$status" -ne 0 ]; then
		return "$status"
	fi
	for record in "${CRUCIBLE_DNS_ANSWERS[@]}"; do
		read -r name ttl class record_type data <<<"$record"
		if [ "$record_type" = "${type^^}" ]; then
			printf '%s\n' "$data"
		fi
	done
}

# Prints the names for an IPv4 address
# Usage: dns.reverse <address> [server]
function dns.reverse {
	if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
		logging.error "dns.reverse: usage is dns.reverse <ADDRESS> [SERVER]"
		return 1
	fi
	local a b c d
	if ! [[ "$1" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]] || ! network.verify_host "$1"; then
		logging.error "Not an IPv4 address: $1"
		return 1
	fi
	a="${BASH_REMATCH[1]}"
	b="${BASH_REMATCH[2]}"
	c="${BASH_REMATCH[3]}"
	d="${BASH_REMATCH[4]}"
	dns.resolve "$((10#$d)).$((10#$c)).$((10#$b)).$((10#$a)).in-addr.arpa" PTR "${2:-}"
}
