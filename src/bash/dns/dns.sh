#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require io/network/udp

function dns.poc {
    local response
    network.udp 8.8.8.8 53
    # RECORD symbolizing QUERY for A for example.com
    # https://routley.io/posts/hand-writing-dns-messages
    printf "\xAA\xAA\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x07\x65\x78\x61\x6d\x70\x6c\x65\x03\x63\x6f\x6d\x00\x00\x01\x00\x01" >&"$CRUCIBLE_NETWORK_FD"
    network.udp.receive "$CRUCIBLE_NETWORK_FD"
    maps.entries DNS_RESPONSE_"$id"
    logging.info "Things left:"
    logging.info "1. Write different query types (A, AAAA, TXT...)"
    logging.info "2. Parse input into request"
}
