#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/dns/dns -p
cd tmp/dns/dns || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require dns/dns

declare -a tests

tests=("dns.test.build_query" "dns.test.build_query_refuses")
tests+=("dns.test.parse_real_answers" "dns.test.parse_header_and_question")
tests+=("dns.test.parse_synthetic" "dns.test.parse_ipv6")
tests+=("dns.test.parse_error_codes" "dns.test.parse_hostile_messages")
tests+=("dns.test.query" "dns.test.resolve" "dns.test.reverse")
tests+=("dns.test.query_statuses" "dns.test.query_server_failures")
tests+=("dns.test.server_selection")

# Real answers of a public resolver, captured with a separate tool, and
# messages made by a separate encoder for what the real world does not offer.
# Their id is 4660 (1234 hexadecimal).
declare -A real_queries real_answers synthetic
real_queries[a]='123401000001000000000000076578616D706C6503636F6D0000010001'
real_answers[a]='123481800001000200000000076578616D706C6503636F6D0000010001C00C000100010000011500046814179AC00C00010001000001150004AC4293F3'
real_queries[aaaa]='123401000001000000000000076578616D706C6503636F6D00001C0001'
real_answers[aaaa]='123481800001000200000000076578616D706C6503636F6D00001C0001C00C001C00010000000B0010260647000010000000000000AC4293F3C00C001C00010000000B00102606470000100000000000006814179A'
real_queries[mx]='123401000001000000000000076578616D706C6503636F6D00000F0001'
real_answers[mx]='123481800001000100000000076578616D706C6503636F6D00000F0001C00C000F00010000000C0003000000'
real_queries[txt]='123401000001000000000000076578616D706C6503636F6D0000100001'
real_answers[txt]='123481800001000200000000076578616D706C6503636F6D0000100001C00C0010000100000108000C0B763D73706631202D616C6CC00C00100001000001080021205F6B326E31793476773371746234736B6478396537647874393771726D6D7139'
real_queries[ns]='123401000001000000000000076578616D706C6503636F6D0000020001'
real_answers[ns]='123481800001000200000000076578616D706C6503636F6D0000020001C00C000200010001283300150468657261026E730A636C6F7564666C617265C014C00C0002000100012833000A07656C6C696F7474C02E'
real_queries[soa]='123401000001000000000000076578616D706C6503636F6D0000060001'
real_answers[soa]='123481800001000100000000076578616D706C6503636F6D0000060001C00C00060001000005B7003207656C6C696F7474026E730A636C6F7564666C617265C01403646E73C0349006F398000027100000096000093A8000000708'
real_queries[cname]='123401000001000000000000037777770469616E61036F72670000050001'
real_answers[cname]='123481800001000100000000037777770469616E61036F72670000050001C00C0005000100000E100021037777770469616E61036F72670363646E0A636C6F7564666C617265036E657400'
real_queries[ptr]='123401000001000000000000013101310131013107696E2D61646472046172706100000C0001'
real_answers[ptr]='123481800001000100000000013101310131013107696E2D61646472046172706100000C0001C00C000C00010000035E0011036F6E65036F6E65036F6E65036F6E6500'
real_queries[nxdomain]='1234010000010000000000000C646F65736E6F746578697374076578616D706C6503636F6D0000010001'
real_answers[nxdomain]='1234818000010000000100000C646F65736E6F746578697374076578616D706C6503636F6D0000010001C0190006000100000708003207656C6C696F7474026E730A636C6F7564666C617265C02103646E73C0419006F398000027100000096000093A8000000708'
real_queries[txt_dmarc]='123401000001000000000000065F646D61726306676F6F676C6503636F6D0000100001'
real_answers[txt_dmarc]='123481800001000100000000065F646D61726306676F6F676C6503636F6D0000100001C00C001000010000012C003B3A763D444D415243313B20703D72656A6563743B207275613D6D61696C746F3A6D61696C617574682D7265706F72747340676F6F676C652E636F6D'
real_queries[srv]='123401000001000000000000045F736970045F746370076578616D706C6503636F6D0000210001'
real_answers[srv]='123481800001000000010000045F736970045F746370076578616D706C6503636F6D0000210001C0160006000100000708003207656C6C696F7474026E730A636C6F7564666C617265C01E03646E73C03E9006F398000027100000096000093A8000000708'
synthetic[srv]='123481800001000100000000045F736970045F746370076578616D706C6503636F6D0000210001C00C002100010000012C000C000A003C13C403736970C016'
synthetic[txt_multi]='1234818000010001000000000174076578616D706C6503636F6D0000100001C00C001000010000003C001B036120620F71756F746522616E645C736C617368000562656C6C07'
synthetic[weird_name]='12348180000100010000000008612E6220635C6401076578616D706C6503636F6D0000010001C00C00010001000000050004C0000207'
synthetic[nxdomain]='123481830001000000000000046E6F7065076578616D706C6503636F6D0000010001'
synthetic[servfail]='123481820001000000000000046E6F7065076578616D706C6503636F6D0000010001'
synthetic[refused]='123481850001000000000000046E6F7065076578616D706C6503636F6D0000010001'
synthetic[glue]='123485800001000100000002076578616D706C6503636F6D0000020001C00C0002000100000E100011036E7331076578616D706C6503636F6D00036E7331076578616D706C6503636F6D000001000100000E100004C0000235036E7331076578616D706C6503636F6D00001C000100000E10001020010DB8000000000000000000000053'
synthetic[v6_loopback]='123481800001000100000000027636076578616D706C6503636F6D00001C0001C00C001C000100000001001000000000000000000000000000000001'
synthetic[v6_any]='123481800001000100000000027636076578616D706C6503636F6D00001C0001C00C001C000100000001001000000000000000000000000000000000'
synthetic[v6_single_zero]='123481800001000100000000027636076578616D706C6503636F6D00001C0001C00C001C000100000001001020010DB8000000010001000100010001'
synthetic[v6_two_runs]='123481800001000100000000027636076578616D706C6503636F6D00001C0001C00C001C000100000001001020010000000000010000000000000001'
synthetic[v6_equal_runs]='123481800001000100000000027636076578616D706C6503636F6D00001C0001C00C001C000100000001001020010000000100000000000100010001'
synthetic[v6_trailing]='123481800001000100000000027636076578616D706C6503636F6D00001C0001C00C001C0001000000010010FE800000000000000000000000000000'
synthetic[unknown_type]='1234818000010001000000000178076578616D706C6503636F6D0000630001C00C00630001000000070004DEADBEEF'
synthetic[chaos_class]='1234818000010001000000000178076578616D706C6503636F6D0000630001C00C001000030000000000050474657374'
synthetic[loop_pointer]='123481800001000000000000C00C00010001'
synthetic[pointer_chain]='123481800001000000000000C00EC00C00010001'
synthetic[rdlength_overrun]='123481800001000100000000076578616D706C6503636F6D0000010001C00C000100010000000100C801020304'
synthetic[count_overrun]='123481800001000500000000076578616D706C6503636F6D0000010001C00C0001000100000001000401020304'
synthetic[reserved_label_type]='1234818000010000000000004161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161610000010001'
synthetic[truncated_in_name]='12348180000100000000000007657861'
synthetic[truncated_in_record]='123481800001000100000000076578616D706C6503636F6D0000010001C00C0001000100000001000401'
synthetic[txt_overrun]='123481800001000100000000076578616D706C6503636F6D0000010001C00C0010000100000001000409616263'
synthetic[short_a]='123481800001000100000000076578616D706C6503636F6D0000010001C00C00010001000000010003010203'
synthetic[soa_short]='123481800001000100000000076578616D706C6503636F6D0000010001C00C00060001000000010012016101620001630164000000000000000000'
synthetic[too_short]='1234818000010000'

export CRUCIBLE_DNS_TIMEOUT=3
export CRUCIBLE_DNS_QUERY_ID=4660
export CRUCIBLE_DNS_PORT=18701

function records {
    # one record to a line, from the array that is named
    local -n _records="$1"
    printf '%s\n' "${_records[@]}"
}

# Every server serves one connection and then stops
function serve_dns {
    # usage: serve_dns <port> <hex of the message> <file the request is written to>
    local framed
    printf -v framed '%04X%s' $((${#2} / 2)) "$2"
    ( printf '%b' "$(sed 's/../\\x&/g' <<<"$framed")" | timeout 20 nc -N -l 127.0.0.1 "$1" >"$3" 2>/dev/null ) &
    wait_for_port tcp "$1"
}

function request_hex {
    xxd -p "$1" | tr -d '\n' | tr 'a-f' 'A-F'
}

function dns.test.build_query {
    intro "dns.build_query makes the queries that a separate encoder made"
    local type
    assert_equals "${real_queries[a]}" "$(dns.build_query example.com A 4660)" "A for example.com"
    assert_equals "${real_queries[a]}" "$(dns.build_query example.com. a 4660)" "trailing dot, lower case type"
    assert_equals "${real_queries[a]}" "$(CRUCIBLE_DNS_QUERY_ID=4660 dns.build_query example.com)" "type defaults to A, id from the environment"
    assert_equals "${real_queries[a]}" "$(dns.build_query example.com 1 4660)" "type as a number"
    for type in aaaa mx txt ns soa; do
        assert_equals "${real_queries[$type]}" "$(dns.build_query example.com "$type" 4660)" "query for $type"
    done
    assert_equals "${real_queries[cname]}" "$(dns.build_query www.iana.org CNAME 4660)" "CNAME"
    assert_equals "${real_queries[ptr]}" "$(dns.build_query 1.1.1.1.in-addr.arpa PTR 4660)" "PTR"
    assert_equals "${real_queries[txt_dmarc]}" "$(dns.build_query _dmarc.google.com TXT 4660)" "underscore in a label"
    assert_equals "${real_queries[srv]}" "$(dns.build_query _sip._tcp.example.com SRV 4660)" "SRV"
    assert_equals "1234010000010000000000000000020001" "$(dns.build_query . NS 4660)" "the root"
    assert_equals "FFFF0100000100000000000001610000010001" "$(dns.build_query a A 65535)" "highest id"
    assert_equals "1234010000010000000000000161000063" "$(dns.build_query a 99 4660 | cut -c1-34)" "type number 99"
    local first second
    first="$(CRUCIBLE_DNS_QUERY_ID='' dns.build_query example.com)"
    second="$(CRUCIBLE_DNS_QUERY_ID='' dns.build_query example.com)"
    [[ "$first" =~ ^[0-9A-F]{4}0100000100000000000007 ]] || fail "A random id should still make a query: $first"
    test "$first" != "$second" || fail "Two queries got the same random id"
    success
}

function dns.test.build_query_refuses {
    intro "dns.build_query refuses what it cannot encode"
    local long label64
    printf -v long '%*s' 64 ''
    label64="${long// /a}"
    assert_false "empty label" quietly dns.build_query a..b
    assert_false "label of 64 characters" quietly dns.build_query "$label64.com"
    assert_true "label of 63 characters" quietly dns.build_query "${label64:1}.com"
    assert_false "name of more than 253 characters" quietly dns.build_query "$(printf 'abcdefghi.%.0s' {1..26})com"
    assert_false "space in a name" quietly dns.build_query "a b.com"
    assert_false "slash in a name" quietly dns.build_query "a/b.com"
    assert_false "two trailing dots" quietly dns.build_query "example.com.."
    assert_false "unknown type" quietly dns.build_query example.com WIBBLE
    assert_false "type number out of range" quietly dns.build_query example.com 70000
    assert_false "id out of range" quietly dns.build_query example.com A 65536
    assert_false "id that is no number" quietly dns.build_query example.com A abc
    assert_false "no arguments" quietly dns.build_query
    success
}

function dns.test.parse_real_answers {
    intro "dns.parse_response: answers of a real resolver"
    dns.parse_response "${real_answers[a]}" || fail "A"
    assert_equals "example.com. 277 IN A 104.20.23.154
example.com. 277 IN A 172.66.147.243" "$(records CRUCIBLE_DNS_ANSWERS)" "A"
    dns.parse_response "${real_answers[aaaa]}" || fail "AAAA"
    assert_equals "example.com. 11 IN AAAA 2606:4700:10::ac42:93f3
example.com. 11 IN AAAA 2606:4700:10::6814:179a" "$(records CRUCIBLE_DNS_ANSWERS)" "AAAA"
    dns.parse_response "${real_answers[mx]}" || fail "MX"
    assert_equals "example.com. 12 IN MX 0 ." "$(records CRUCIBLE_DNS_ANSWERS)" "MX with the root as exchange"
    dns.parse_response "${real_answers[txt]}" || fail "TXT"
    assert_equals 'example.com. 264 IN TXT "v=spf1 -all"
example.com. 264 IN TXT "_k2n1y4vw3qtb4skdx9e7dxt97qrmmq9"' "$(records CRUCIBLE_DNS_ANSWERS)" "TXT"
    dns.parse_response "${real_answers[ns]}" || fail "NS"
    assert_equals "example.com. 75827 IN NS hera.ns.cloudflare.com.
example.com. 75827 IN NS elliott.ns.cloudflare.com." "$(records CRUCIBLE_DNS_ANSWERS)" "NS"
    dns.parse_response "${real_answers[soa]}" || fail "SOA"
    assert_equals "example.com. 1463 IN SOA elliott.ns.cloudflare.com. dns.cloudflare.com. 2416374680 10000 2400 604800 1800" "$(records CRUCIBLE_DNS_ANSWERS)" "SOA"
    dns.parse_response "${real_answers[cname]}" || fail "CNAME"
    assert_equals "www.iana.org. 3600 IN CNAME www.iana.org.cdn.cloudflare.net." "$(records CRUCIBLE_DNS_ANSWERS)" "CNAME"
    dns.parse_response "${real_answers[ptr]}" || fail "PTR"
    assert_equals "1.1.1.1.in-addr.arpa. 862 IN PTR one.one.one.one." "$(records CRUCIBLE_DNS_ANSWERS)" "PTR"
    dns.parse_response "${real_answers[txt_dmarc]}" || fail "TXT with ; and ="
    assert_equals '_dmarc.google.com. 300 IN TXT "v=DMARC1; p=reject; rua=mailto:mailauth-reports@google.com"' "$(records CRUCIBLE_DNS_ANSWERS)" "TXT of dmarc"
    dns.parse_response "${real_answers[srv]}" || fail "no data"
    assert_equals "0" "${#CRUCIBLE_DNS_ANSWERS[@]}" "no answers when there are none"
    assert_equals "example.com. 1800 IN SOA elliott.ns.cloudflare.com. dns.cloudflare.com. 2416374680 10000 2400 604800 1800" "$(records CRUCIBLE_DNS_AUTHORITIES)" "the authority section"
    success
}

function dns.test.parse_header_and_question {
    intro "dns.parse_response: header and question"
    dns.parse_response "${real_answers[a]}"
    assert_equals "4660" "${CRUCIBLE_DNS_RESPONSE[id]}" "id"
    assert_equals "1" "${CRUCIBLE_DNS_RESPONSE[qr]}" "qr"
    assert_equals "QUERY" "${CRUCIBLE_DNS_RESPONSE[opcode]}" "opcode"
    assert_equals "0" "${CRUCIBLE_DNS_RESPONSE[aa]}" "aa"
    assert_equals "0" "${CRUCIBLE_DNS_RESPONSE[tc]}" "tc"
    assert_equals "1" "${CRUCIBLE_DNS_RESPONSE[rd]}" "rd"
    assert_equals "1" "${CRUCIBLE_DNS_RESPONSE[ra]}" "ra"
    assert_equals "0" "${CRUCIBLE_DNS_RESPONSE[rcode]}" "rcode"
    assert_equals "NOERROR" "${CRUCIBLE_DNS_RESPONSE[rcode_name]}" "rcode name"
    assert_equals "1 2 0 0" "${CRUCIBLE_DNS_RESPONSE[qdcount]} ${CRUCIBLE_DNS_RESPONSE[ancount]} ${CRUCIBLE_DNS_RESPONSE[nscount]} ${CRUCIBLE_DNS_RESPONSE[arcount]}" "counts"
    assert_equals "example.com." "${CRUCIBLE_DNS_RESPONSE[qname]}" "qname"
    assert_equals "A" "${CRUCIBLE_DNS_RESPONSE[qtype]}" "qtype"
    assert_equals "IN" "${CRUCIBLE_DNS_RESPONSE[qclass]}" "qclass"
    dns.parse_response "${synthetic[glue]}"
    assert_equals "1" "${CRUCIBLE_DNS_RESPONSE[aa]}" "authoritative answer"
    assert_equals "1 1 1" "${CRUCIBLE_DNS_RESPONSE[qr]} ${CRUCIBLE_DNS_RESPONSE[rd]} ${CRUCIBLE_DNS_RESPONSE[ra]}" "flags 8580: response, recursion desired and available"
    dns.parse_response "${real_answers[a]}"
    dns.parse_response "${synthetic[nxdomain]}"
    assert_equals "0" "${#CRUCIBLE_DNS_ANSWERS[@]}" "a new parse starts from nothing"
    success
}

function dns.test.parse_synthetic {
    intro "dns.parse_response: compression, escapes, sections, unknown types"
    dns.parse_response "${synthetic[srv]}" || fail "SRV"
    assert_equals "_sip._tcp.example.com. 300 IN SRV 10 60 5060 sip.example.com." "$(records CRUCIBLE_DNS_ANSWERS)" "SRV with a compressed target"
    dns.parse_response "${synthetic[txt_multi]}" || fail "TXT"
    assert_equals 't.example.com. 60 IN TXT "a b" "quote\"and\\slash" "" "bell\007"' "$(records CRUCIBLE_DNS_ANSWERS)" "TXT with several strings and escapes"
    dns.parse_response "${synthetic[weird_name]}" || fail "weird name"
    assert_equals 'a\.b\032c\\d\001.example.com. 5 IN A 192.0.2.7' "$(records CRUCIBLE_DNS_ANSWERS)" "dot, space, backslash and control byte in a label"
    assert_equals 'a\.b\032c\\d\001.example.com.' "${CRUCIBLE_DNS_RESPONSE[qname]}" "also in the question"
    dns.parse_response "${synthetic[glue]}" || fail "glue"
    assert_equals "example.com. 3600 IN NS ns1.example.com." "$(records CRUCIBLE_DNS_ANSWERS)" "answer"
    assert_equals "ns1.example.com. 3600 IN A 192.0.2.53
ns1.example.com. 3600 IN AAAA 2001:db8::53" "$(records CRUCIBLE_DNS_ADDITIONALS)" "additional section"
    dns.parse_response "${synthetic[unknown_type]}" || fail "unknown type"
    assert_equals 'x.example.com. 7 IN TYPE99 \# 4 DEADBEEF' "$(records CRUCIBLE_DNS_ANSWERS)" "unknown type, RFC 3597"
    assert_equals "TYPE99" "${CRUCIBLE_DNS_RESPONSE[qtype]}" "unknown type in the question"
    dns.parse_response "${synthetic[chaos_class]}" || fail "chaos"
    assert_equals 'x.example.com. 0 CH TXT "test"' "$(records CRUCIBLE_DNS_ANSWERS)" "class CH"
    dns.parse_response "${synthetic[short_a]}" || fail "A with the wrong length"
    assert_equals 'example.com. 1 IN A \# 3 010203' "$(records CRUCIBLE_DNS_ANSWERS)" "an A record that is not 4 bytes is kept as it came"
    success
}

function dns.test.parse_ipv6 {
    intro "dns.parse_response: IPv6 the way RFC 5952 writes it"
    local case_name expected
    declare -A expectations
    expectations=([v6_loopback]="::1" [v6_any]="::" [v6_single_zero]="2001:db8:0:1:1:1:1:1" [v6_two_runs]="2001:0:0:1::1" [v6_equal_runs]="2001:0:1::1:1:1" [v6_trailing]="fe80::")
    for case_name in "${!expectations[@]}"; do
        expected="v6.example.com. 1 IN AAAA ${expectations[$case_name]}"
        dns.parse_response "${synthetic[$case_name]}" || fail "$case_name"
        assert_equals "$expected" "$(records CRUCIBLE_DNS_ANSWERS)" "$case_name"
    done
    success
}

function dns.test.parse_error_codes {
    intro "dns.parse_response: names of the response codes"
    dns.parse_response "${synthetic[nxdomain]}"
    assert_equals "3 NXDOMAIN" "${CRUCIBLE_DNS_RESPONSE[rcode]} ${CRUCIBLE_DNS_RESPONSE[rcode_name]}" "nxdomain"
    dns.parse_response "${synthetic[servfail]}"
    assert_equals "2 SERVFAIL" "${CRUCIBLE_DNS_RESPONSE[rcode]} ${CRUCIBLE_DNS_RESPONSE[rcode_name]}" "servfail"
    dns.parse_response "${synthetic[refused]}"
    assert_equals "5 REFUSED" "${CRUCIBLE_DNS_RESPONSE[rcode]} ${CRUCIBLE_DNS_RESPONSE[rcode_name]}" "refused"
    success
}

function dns.test.parse_hostile_messages {
    intro "dns.parse_response: messages that are made to cause trouble"
    local case_name start
    start=$SECONDS
    for case_name in loop_pointer pointer_chain rdlength_overrun count_overrun reserved_label_type truncated_in_name truncated_in_record txt_overrun soa_short too_short; do
        dns.parse_response "${synthetic[$case_name]}" >/dev/null 2>&1
        test $? -ne 0 || fail "$case_name should have been refused"
    done
    test $((SECONDS - start)) -le 5 || fail "Hostile messages took $((SECONDS - start)) seconds"
    assert_false "not hexadecimal" quietly dns.parse_response "ZZ"
    assert_false "odd number of digits" quietly dns.parse_response "123"
    assert_false "empty" quietly dns.parse_response ""
    assert_false "a header only, with a question that is not there" quietly dns.parse_response "123481800001000000000000"
    dns.parse_response "123481800000000000000000" || fail "an empty message with no questions is fine"
    success
}

function dns.test.query {
    intro "dns.query over TCP against a stand in server"
    local framed
    serve_dns 18701 "${real_answers[a]}" query-request.txt
    dns.query example.com A 127.0.0.1 >query-output.txt
    assert_equals "0" "$?" "status"
    wait
    printf -v framed '%04X%s' $((${#real_queries[a]} / 2)) "${real_queries[a]}"
    assert_equals "$framed" "$(request_hex query-request.txt)" "the query as it was sent, with its length in front"
    assert_equals "example.com. 277 IN A 104.20.23.154
example.com. 277 IN A 172.66.147.243" "$(cat query-output.txt)" "printed records"
    assert_equals "2" "${#CRUCIBLE_DNS_ANSWERS[@]}" "the variables are filled"
    assert_equals "NOERROR" "${CRUCIBLE_DNS_RESPONSE[rcode_name]}" "response"
    rm query-output.txt
    success
}

function dns.test.resolve {
    intro "dns.resolve prints the data of the records that were asked for"
    serve_dns 18701 "${real_answers[a]}" resolve-request.txt
    assert_equals "104.20.23.154
172.66.147.243" "$(dns.resolve example.com A 127.0.0.1)" "addresses"
    wait
    CRUCIBLE_DNS_QUERY_ID=4660 serve_dns 18701 "${real_answers[mx]}" resolve-request.txt
    assert_equals "0 ." "$(dns.resolve example.com MX 127.0.0.1)" "mx"
    wait
    serve_dns 18701 "${real_answers[txt]}" resolve-request.txt
    assert_equals '"v=spf1 -all"
"_k2n1y4vw3qtb4skdx9e7dxt97qrmmq9"' "$(dns.resolve example.com TXT 127.0.0.1)" "txt"
    wait
    # An alias that the server did not follow all the way has no A records to show
    serve_dns 18701 "${real_answers[cname]}" resolve-request.txt
    assert_equals "www.iana.org.cdn.cloudflare.net." "$(dns.resolve www.iana.org CNAME 127.0.0.1)" "cname"
    wait
    success
}

function dns.test.reverse {
    intro "dns.reverse"
    serve_dns 18701 "${real_answers[ptr]}" reverse-request.txt
    assert_equals "one.one.one.one." "$(dns.reverse 1.1.1.1 127.0.0.1)" "name of 1.1.1.1"
    wait
    # Behind the length and the id the query for the reversed name is the one that was captured
    assert_equals "${real_queries[ptr]:4}" "$(request_hex reverse-request.txt | cut -c9-)" "asked for the reversed name"
    assert_false "not an address" quietly dns.reverse one.one.one.one 127.0.0.1
    assert_false "octet out of range" quietly dns.reverse 1.1.1.256 127.0.0.1
    assert_false "too few octets" quietly dns.reverse 1.1.1 127.0.0.1
    success
}

function dns.test.query_statuses {
    intro "dns.query: the status says what happened"
    serve_dns 18701 "${synthetic[nxdomain]}" status-request.txt
    dns.query nope.example.com A 127.0.0.1 >/dev/null 2>&1
    assert_equals "2" "$?" "a name that does not exist"
    wait
    serve_dns 18701 "${real_answers[srv]}" status-request.txt
    dns.query _sip._tcp.example.com SRV 127.0.0.1 >/dev/null 2>&1
    assert_equals "3" "$?" "a name without records of the type"
    wait
    serve_dns 18701 "${synthetic[servfail]}" status-request.txt
    dns.query nope.example.com A 127.0.0.1 >/dev/null 2>&1
    assert_equals "1" "$?" "servfail"
    wait
    serve_dns 18701 "${synthetic[refused]}" status-request.txt
    dns.query nope.example.com A 127.0.0.1 >/dev/null 2>&1
    assert_equals "1" "$?" "refused"
    wait
    success
}

function dns.test.query_server_failures {
    intro "dns.query: a server that misbehaves"
    local start
    # Answers another question than the one that was asked
    serve_dns 18701 "${real_answers[a]}" failure-request.txt
    CRUCIBLE_DNS_QUERY_ID=4661 dns.query example.com A 127.0.0.1 >/dev/null 2>&1
    assert_equals "1" "$?" "answer with another id"
    wait
    # Takes the connection and says nothing
    ( printf '' | timeout 20 nc -N -l 127.0.0.1 18701 >failure-request.txt 2>/dev/null ) &
    wait_for_port tcp 18701
    dns.query example.com A 127.0.0.1 >/dev/null 2>&1
    assert_equals "1" "$?" "connection closed without an answer"
    wait
    # Announces 100 bytes and sends 10
    ( printf '\x00\x64%s' "0123456789" | timeout 20 nc -N -l 127.0.0.1 18701 >failure-request.txt 2>/dev/null ) &
    wait_for_port tcp 18701
    dns.query example.com A 127.0.0.1 >/dev/null 2>&1
    assert_equals "1" "$?" "answer that stops halfway"
    wait
    # Is silent
    ( sleep 8 | timeout 20 nc -l 127.0.0.1 18701 >/dev/null 2>&1 ) &
    wait_for_port tcp 18701
    start=$SECONDS
    CRUCIBLE_DNS_TIMEOUT=1 dns.query example.com A 127.0.0.1 >/dev/null 2>&1
    assert_equals "1" "$?" "silent server"
    test $((SECONDS - start)) -le 4 || fail "Took $((SECONDS - start)) seconds with a timeout of 1"
    kill %% 2>/dev/null
    wait 2>/dev/null
    # Nothing listens
    dns.query example.com A 127.0.0.1 >/dev/null 2>&1
    assert_equals "1" "$?" "nothing listening"
    # Not an answer at all
    serve_dns 18701 "ABCDEF" failure-request.txt
    dns.query example.com A 127.0.0.1 >/dev/null 2>&1
    assert_equals "1" "$?" "a message of three bytes"
    wait
    success
}

function dns.test.server_selection {
    intro "which server is asked"
    printf '# a comment\nsearch example.com\nnameserver 2001:db8::1\nnameserver 192.0.2.1\nnameserver 192.0.2.2\n' >resolv.conf
    assert_equals "192.0.2.1" "$(CRUCIBLE_DNS_RESOLV_CONF=resolv.conf dns._server)" "first IPv4 nameserver of resolv.conf"
    assert_equals "198.51.100.7" "$(CRUCIBLE_DNS_SERVER=198.51.100.7 CRUCIBLE_DNS_RESOLV_CONF=resolv.conf dns._server)" "the environment comes before resolv.conf"
    assert_equals "203.0.113.9" "$(CRUCIBLE_DNS_SERVER=198.51.100.7 CRUCIBLE_DNS_RESOLV_CONF=resolv.conf dns._server 203.0.113.9)" "the argument comes first"
    printf 'search example.com\nnameserver 2001:db8::1\n' >resolv.conf
    assert_false "only an IPv6 nameserver" quietly env CRUCIBLE_DNS_RESOLV_CONF=resolv.conf bash -c 'source .mould; require dns/dns; dns._server'
    CRUCIBLE_DNS_RESOLV_CONF=does-not-exist dns._server >/dev/null 2>&1
    test $? -ne 0 || fail "A resolv.conf that is not there should fail"
    assert_false "an invalid server" quietly dns.query example.com A "not a host"
    rm resolv.conf
    success
}

echo "Testing dns/dns"

for test in "${tests[@]}"; do
    "$test"
done

teardown
