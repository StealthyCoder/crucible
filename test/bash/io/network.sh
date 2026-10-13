#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/io/network -p
cd tmp/io/network || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require io/network/network

declare -a tests

tests=("io.network.verify_host" "io.network.verify_port")
tests+=("io.network.tcp.connect_send_receive" "io.network.tcp.inline")
tests+=("io.network.tcp.refused" "io.network.tcp.invalid_arguments")
tests+=("io.network.tcp.receive_timeout" "io.network.tcp.close")
tests+=("io.network.tcp.binary" "io.network.tcp.read_in_steps")
tests+=("io.network.udp.connect_send_receive" "io.network.udp.inline")
tests+=("io.network.udp.send_hex" "io.network.udp.receive_timeout")
tests+=("io.network.udp.invalid_arguments")

# Every server in this file serves one connection and then stops
function serve_tcp {
    # usage: serve_tcp <port> <response> <file the request is written to>
    ( printf '%b' "$2" | timeout 20 nc -N -l 127.0.0.1 "$1" >"$3" 2>/dev/null ) &
    wait_for_port tcp "$1"
}

function serve_udp {
    # usage: serve_udp <port> <response> <file the request is written to>
    # A udp listener never sees the end of a conversation, stop_servers ends it
    ( printf '%b' "$2" | timeout 20 nc -u -l 127.0.0.1 "$1" >"$3" 2>/dev/null ) &
    wait_for_port udp "$1"
}

function stop_servers {
    kill "$(jobs -p)" 2>/dev/null
    wait 2>/dev/null
}

function io.network.verify_host {
    intro "io.network.verify_host"
    assert_true "ipv4 address" network.verify_host 127.0.0.1
    assert_true "plain name" network.verify_host localhost
    assert_true "fully qualified name" network.verify_host example.com
    assert_true "name with hyphens" network.verify_host my-host.example.com
    assert_true "name with a trailing dot" network.verify_host example.com.
    assert_false "empty host" network.verify_host ""
    assert_false "ipv4 octet out of range" network.verify_host 999.1.1.1
    assert_false "name starting with a hyphen" network.verify_host -bad.example.com
    assert_false "name ending with a hyphen" network.verify_host bad-.example.com
    assert_false "name with a space" network.verify_host "bad host"
    assert_false "name with a slash" network.verify_host "bad/host"
    assert_false "name with a semicolon" network.verify_host 'a;b'
    success
}

function io.network.verify_port {
    intro "io.network.verify_port"
    assert_true "http" network.verify_port 80
    assert_true "lowest port" network.verify_port 1
    assert_true "highest port" network.verify_port 65535
    assert_false "port zero" network.verify_port 0
    assert_false "port too high" network.verify_port 65536
    assert_false "negative port" network.verify_port -1
    assert_false "not a number" network.verify_port http
    assert_false "empty port" network.verify_port ""
    success
}

function io.network.tcp.connect_send_receive {
    intro "io.network.tcp: connect, send and receive"
    serve_tcp 18201 'pong\n' tcp-request.txt
    network.tcp 127.0.0.1 18201
    test -n "$CRUCIBLE_NETWORK_FD" || fail "CRUCIBLE_NETWORK_FD was not set"
    network.tcp.send "$CRUCIBLE_NETWORK_FD" "ping"
    assert_equals "pong" "$(network.tcp.receive "$CRUCIBLE_NETWORK_FD" 10)" "response"
    network.tcp.close "$CRUCIBLE_NETWORK_FD"
    wait
    assert_equals "ping" "$(cat tcp-request.txt)" "request"
    success
}

function io.network.tcp.inline {
    intro "io.network.tcp: send and receive in one call"
    serve_tcp 18202 'HTTP/1.1 200 OK\r\n\r\nbody' tcp-request.txt
    assert_equals "$(printf 'HTTP/1.1 200 OK\r\n\r\nbody')" "$(network.tcp 127.0.0.1 18202 "GET / HTTP/1.1\r\n\r\n")" "response"
    wait
    assert_equals "GET / HTTP/1.1" "$(head -n 1 tcp-request.txt | tr -d '\r')" "request"
    success
}

function io.network.tcp.refused {
    intro "io.network.tcp: nothing listening"
    local output
    output="$(network.tcp 127.0.0.1 18299 2>&1)"
    test $? -ne 0 || fail "Connecting to a closed port should fail"
    [[ "$output" == *"Could not connect"* ]] || fail "The failure should be reported, got: $output"
    success
}

function io.network.tcp.invalid_arguments {
    intro "io.network.tcp: invalid arguments"
    ( network.tcp >/dev/null 2>&1 )
    test $? -ne 0 || fail "No arguments should fail"
    ( network.tcp 127.0.0.1 >/dev/null 2>&1 )
    test $? -ne 0 || fail "A missing port should fail"
    ( network.tcp 127.0.0.1 99999 >/dev/null 2>&1 )
    test $? -ne 0 || fail "An invalid port should fail"
    ( network.tcp "bad host" 80 >/dev/null 2>&1 )
    test $? -ne 0 || fail "An invalid host should fail"
    success
}

function io.network.tcp.receive_timeout {
    intro "io.network.tcp: a silent server does not hang the client"
    local start elapsed
    ( sleep 8 | timeout 20 nc -l 127.0.0.1 18203 >/dev/null 2>&1 ) &
    wait_for_port tcp 18203
    network.tcp 127.0.0.1 18203
    start=$SECONDS
    network.tcp.receive "$CRUCIBLE_NETWORK_FD" 1 >/dev/null
    elapsed=$((SECONDS - start))
    test "$elapsed" -le 3 || fail "Receive took $elapsed seconds with a timeout of 1 second"
    network.tcp.close "$CRUCIBLE_NETWORK_FD"
    kill %% 2>/dev/null
    wait 2>/dev/null
    success
}

function io.network.tcp.close {
    intro "io.network.tcp.close"
    local fd
    serve_tcp 18204 '' tcp-request.txt
    network.tcp 127.0.0.1 18204
    fd="$CRUCIBLE_NETWORK_FD"
    test -e "/proc/$$/fd/$fd" || fail "File descriptor $fd is not open"
    network.tcp.close "$fd"
    test ! -e "/proc/$$/fd/$fd" || fail "File descriptor $fd is still open"
    test -z "${CRUCIBLE_NETWORK_FD:-}" || fail "CRUCIBLE_NETWORK_FD still points at the closed descriptor"
    wait
    # Inline calls must not leak descriptors either
    serve_tcp 18205 'x' tcp-request.txt
    local before after
    before="$(ls /proc/$$/fd | wc -l)"
    network.tcp 127.0.0.1 18205 "x" >/dev/null
    after="$(ls /proc/$$/fd | wc -l)"
    assert_equals "$before" "$after" "File descriptors leaked by an inline call"
    wait
    success
}

function io.network.tcp.binary {
    intro "io.network.tcp: every byte value in both directions"
    local bytes want i
    bytes=""
    want=""
    for i in $(seq 0 255); do
        bytes+="$(printf '\\x%02x' "$i")"
        want+="$(printf '%02X' "$i")"
    done
    serve_tcp 18206 "$bytes" tcp-request.txt
    network.tcp 127.0.0.1 18206
    network.tcp.send_hex "$CRUCIBLE_NETWORK_FD" "${want}"
    assert_equals "$want" "$(network.tcp.receive_hex "$CRUCIBLE_NETWORK_FD" 256 5)" "response"
    network.tcp.close "$CRUCIBLE_NETWORK_FD"
    wait
    assert_equals "$(echo "$want" | tr 'A-F' 'a-f')" "$(xxd -p tcp-request.txt | tr -d '\n')" "request"
    success
}

function io.network.tcp.read_in_steps {
    intro "io.network.tcp.receive_hex: what was not asked for yet is kept"
    local first second rest
    # A length of 5, then the message, with NUL bytes right where the reads end
    serve_tcp 18207 '\x00\x05\x12\x00\x34\x00\x56' tcp-request.txt
    network.tcp 127.0.0.1 18207
    network.tcp.receive_hex "$CRUCIBLE_NETWORK_FD" 2 5 >step-one.txt
    network.tcp.receive_hex "$CRUCIBLE_NETWORK_FD" 3 5 >step-two.txt
    network.tcp.receive_hex "$CRUCIBLE_NETWORK_FD" 2 5 >step-three.txt
    first="$(cat step-one.txt)"
    second="$(cat step-two.txt)"
    rest="$(cat step-three.txt)"
    assert_equals "0005" "$first" "the length"
    assert_equals "120034" "$second" "the first three bytes of the message"
    assert_equals "0056" "$rest" "the end of the message"
    network.tcp.close "$CRUCIBLE_NETWORK_FD"
    wait
    # Asking for more than comes fails and says what did come
    serve_tcp 18208 '\x01\x02' tcp-request.txt
    network.tcp 127.0.0.1 18208
    network.tcp.receive_hex "$CRUCIBLE_NETWORK_FD" 5 2 >step-one.txt
    test $? -ne 0 || fail "Reading more than the server sends should fail"
    assert_equals "0102" "$(cat step-one.txt)" "what did arrive"
    network.tcp.close "$CRUCIBLE_NETWORK_FD"
    wait
    # The leftovers of one connection are not for the next one that gets the same descriptor
    serve_tcp 18209 '\x00\x00\x00\x00' tcp-request.txt
    network.tcp 127.0.0.1 18209
    network.tcp.receive_hex "$CRUCIBLE_NETWORK_FD" 1 5 >step-one.txt
    network.tcp.close "$CRUCIBLE_NETWORK_FD"
    wait
    serve_tcp 18210 '\xAA\xBB' tcp-request.txt
    network.tcp 127.0.0.1 18210
    network.tcp.receive_hex "$CRUCIBLE_NETWORK_FD" 2 5 >step-one.txt
    assert_equals "AABB" "$(cat step-one.txt)" "a new connection starts with an empty buffer"
    network.tcp.close "$CRUCIBLE_NETWORK_FD"
    wait
    rm step-one.txt step-two.txt step-three.txt
    success
}

function io.network.udp.connect_send_receive {
    intro "io.network.udp: connect, send and receive"
    serve_udp 18211 'pong' udp-request.txt
    network.udp 127.0.0.1 18211
    test -n "$CRUCIBLE_NETWORK_FD" || fail "CRUCIBLE_NETWORK_FD was not set"
    network.udp.send "$CRUCIBLE_NETWORK_FD" "ping"
    assert_equals "pong" "$(network.udp.receive "$CRUCIBLE_NETWORK_FD" 5)" "response"
    network.udp.close "$CRUCIBLE_NETWORK_FD"
    wait_for_content udp-request.txt
    stop_servers
    assert_equals "ping" "$(cat udp-request.txt)" "request"
    success
}

function io.network.udp.inline {
    intro "io.network.udp: send and receive in one call"
    serve_udp 18212 'pong' udp-request.txt
    assert_equals "pong" "$(network.udp 127.0.0.1 18212 "ping")" "response"
    wait_for_content udp-request.txt
    stop_servers
    assert_equals "ping" "$(cat udp-request.txt)" "request"
    success
}

function io.network.udp.send_hex {
    intro "io.network.udp.send_hex: a datagram with NUL bytes"
    serve_udp 18213 '' udp-request.txt
    network.udp 127.0.0.1 18213
    network.udp.send_hex "$CRUCIBLE_NETWORK_FD" "00FF10aB"
    network.udp.close "$CRUCIBLE_NETWORK_FD"
    wait_for_content udp-request.txt
    stop_servers
    assert_equals "00ff10ab" "$(xxd -p udp-request.txt)" "request with NUL bytes"
    success
}

function io.network.udp.receive_timeout {
    intro "io.network.udp.receive: nothing arrives"
    local start elapsed
    network.udp 127.0.0.1 18215
    start=$SECONDS
    network.udp.receive "$CRUCIBLE_NETWORK_FD" 1 >/dev/null
    test $? -ne 0 || fail "Receive should fail when nothing arrives"
    elapsed=$((SECONDS - start))
    test "$elapsed" -le 3 || fail "Receive took $elapsed seconds with a timeout of 1 second"
    network.udp.close "$CRUCIBLE_NETWORK_FD"
    success
}

function io.network.udp.invalid_arguments {
    intro "io.network.udp: invalid arguments"
    ( network.udp >/dev/null 2>&1 )
    test $? -ne 0 || fail "No arguments should fail"
    ( network.udp 127.0.0.1 99999 >/dev/null 2>&1 )
    test $? -ne 0 || fail "An invalid port should fail"
    network.udp 127.0.0.1 18214
    ( network.udp.send_hex "$CRUCIBLE_NETWORK_FD" "ABC" >/dev/null 2>&1 )
    test $? -ne 0 || fail "An odd number of hex digits should fail"
    ( network.udp.send_hex "$CRUCIBLE_NETWORK_FD" "ZZ" >/dev/null 2>&1 )
    test $? -ne 0 || fail "Non hexadecimal digits should fail"
    network.udp.close "$CRUCIBLE_NETWORK_FD"
    success
}

echo "Testing io/network"

for test in "${tests[@]}"; do
    "$test"
done

teardown
