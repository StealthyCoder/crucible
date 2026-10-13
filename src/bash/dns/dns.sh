#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require io/network/tcp

# Answers are binary and full of NUL bytes, bash can only read those exactly
# from a stream. That is why DNS is done over TCP (RFC 1035 section 4.2.2):
# the same messages as over UDP, each preceded by its length in two bytes.
function dns.poc {
	local length
	network.tcp 8.8.8.8 53
	# RECORD symbolizing QUERY for A for example.com
	# https://routley.io/posts/hand-writing-dns-messages
	# NOTE: ID = AAAA in decimal is 43690
	network.tcp.send_hex "$CRUCIBLE_NETWORK_FD" "001DAAAA01000001000000000000076578616D706C6503636F6D0000010001"
	length="$(network.tcp.receive_hex "$CRUCIBLE_NETWORK_FD" 2 5)"
	logging.info "Length of the answer: $((16#$length))"
	logging.info "$(network.tcp.receive_hex "$CRUCIBLE_NETWORK_FD" $((16#$length)) 5)"
	network.tcp.close "$CRUCIBLE_NETWORK_FD"
}
