#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/http/http -p
cd tmp/http/http || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require http/http

declare -a tests

tests=("http.test.parse_url" "http.test.encoding")
tests+=("http.test.get" "http.test.get_prints_the_body")
tests+=("http.test.chunked" "http.test.close_delimited" "http.test.big_body")
tests+=("http.test.error_status" "http.test.head" "http.test.no_content")
tests+=("http.test.post" "http.test.put_patch_delete")
tests+=("http.test.headers" "http.test.header_injection")
tests+=("http.test.redirect" "http.test.redirect_changes_method")
tests+=("http.test.redirect_limit")
tests+=("http.test.unsupported_urls" "http.test.refused")
tests+=("http.test.silent_server" "http.test.truncated" "http.test.not_http")
tests+=("http.test.continue_is_skipped")

export CRUCIBLE_HTTP_TIMEOUT=3

# Every server serves one connection and then stops
function serve_http {
    # usage: serve_http <port> <raw response> <file the request is written to>
    ( printf '%b' "$2" | timeout 20 nc -N -l 127.0.0.1 "$1" >"$3" 2>/dev/null ) &
    wait_for_port tcp "$1"
}

function http.test.parse_url {
    intro "http.parse_url"
    assert_equals "http
example.com
80
/" "$(http.parse_url http://example.com)" "just a host"
    assert_equals "http
example.com
8080
/a/b?c=d" "$(http.parse_url 'http://example.com:8080/a/b?c=d#fragment')" "port, path, query and fragment"
    assert_equals "http
example.com
80
/?q=1" "$(http.parse_url 'http://example.com?q=1')" "query without a path"
    assert_equals "http
127.0.0.1
80
/" "$(http.parse_url HTTP://127.0.0.1/)" "scheme in capitals"
    assert_false "https" quietly http.parse_url https://example.com
    assert_false "ftp" quietly http.parse_url ftp://example.com
    assert_false "no scheme" quietly http.parse_url example.com
    assert_false "user and password" quietly http.parse_url http://user:pass@example.com
    assert_false "bad port" quietly http.parse_url http://example.com:99999/
    assert_false "space" quietly http.parse_url 'http://example.com/a b'
    assert_false "newline" quietly http.parse_url $'http://example.com/a\r\nHost: evil'
    assert_false "bad host" quietly http.parse_url 'http://exa_mple.com/'
    success
}

function http.test.encoding {
    intro "http.url_encode, url_decode and form_encode"
    assert_equals "plain-text_1.0~" "$(http.url_encode plain-text_1.0~)" "nothing to encode"
    assert_equals "a%20b%26c%3Dd%2Fe%3F" "$(http.url_encode 'a b&c=d/e?')" "reserved characters"
    assert_equals "%C3%BCn%C3%AFc%C3%B6de" "$(http.url_encode 'ünïcöde')" "utf-8 is encoded per byte"
    assert_equals "a b&c=d/e?" "$(http.url_decode 'a%20b%26c%3Dd%2Fe%3F')" "decode"
    assert_equals "ünïcöde" "$(http.url_decode '%C3%BCn%C3%AFc%C3%B6de')" "decode utf-8"
    assert_equals "50% done+more" "$(http.url_decode '50% done+more')" "a % without digits and a + stay"
    assert_equals "back\\slash" "$(http.url_decode 'back%5Cslash')" "backslash"
    assert_equals "100%00" "$(http.url_decode '100%00')" "a NUL cannot be held and stays encoded"
    local nasty
    nasty=$'tab\there "quotes" \'single\' $HOME `x` \\ newline\nsecond line ✓'
    assert_equals "$nasty" "$(http.url_decode "$(http.url_encode "$nasty")")" "round trip"
    assert_equals "name=Ada&city=New%20York" "$(http.form_encode name Ada city 'New York')" "form"
    assert_false "odd number of arguments" quietly http.form_encode name
    success
}

function http.test.get {
    intro "http.request GET: request and response"
    serve_http 18601 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 11\r\nX-Custom:   padded value  \r\nSet-Cookie: a=1\r\nSet-Cookie: b=2\r\n\r\nhello world' get-request.txt
    http.request GET "http://127.0.0.1:18601/some/path?x=1&y=two" ""
    assert_equals "0" "$?" "status of the request"
    wait
    assert_equals "200" "$CRUCIBLE_HTTP_STATUS" "status code"
    assert_equals "OK" "$CRUCIBLE_HTTP_REASON" "reason"
    assert_equals "hello world" "$CRUCIBLE_HTTP_BODY" "body"
    assert_equals "text/plain" "${CRUCIBLE_HTTP_HEADERS[content-type]}" "header with lower case name"
    assert_equals "padded value" "$(http.header X-CUSTOM)" "header, case insensitive and trimmed"
    assert_equals "a=1, b=2" "$(http.header set-cookie)" "repeated headers are joined"
    assert_false "header that is not there" quietly http.header nothing
    assert_equals "$(printf 'GET /some/path?x=1&y=two HTTP/1.1\r\nHost: 127.0.0.1:18601\r\nUser-Agent: crucible\r\nAccept: */*\r\nConnection: close\r\n\r\n')" "$(cat get-request.txt)" "the request as it was sent"
    assert_equals "http://127.0.0.1:18601/some/path?x=1&y=two" "$CRUCIBLE_HTTP_URL" "url"
    success
}

function http.test.get_prints_the_body {
    intro "http.get prints the body"
    serve_http 18602 'HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello' get-request.txt
    assert_equals "hello" "$(http.get http://127.0.0.1:18602/)" "body"
    wait
    serve_http 18602 'HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello' get-request.txt
    http.get http://127.0.0.1:18602/ >/dev/null
    assert_equals "0" "$?" "status of get"
    wait
    success
}

function http.test.chunked {
    intro "chunked responses"
    serve_http 18603 'HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5;name=value\r\nhello\r\n7\r\n, world\r\nA\r\n0123456789\r\n0\r\nTrailer-Header: x\r\n\r\n' chunked-request.txt
    http.get http://127.0.0.1:18603/ >/dev/null
    assert_equals "0" "$?" "status"
    wait
    assert_equals "hello, world0123456789" "$CRUCIBLE_HTTP_BODY" "chunks put together"
    serve_http 18603 'HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n4\r\nline\r\n2\r\n\n\n\r\n2\r\nok\r\n0\r\n\r\n' chunked-request.txt
    http.get http://127.0.0.1:18603/ >/dev/null
    wait
    assert_equals $'line\n\nok' "$CRUCIBLE_HTTP_BODY" "line breaks inside a chunk survive"
    serve_http 18603 'HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nzz\r\nhello\r\n' chunked-request.txt
    http.get http://127.0.0.1:18603/ >/dev/null 2>&1
    assert_equals "1" "$?" "a chunk size that is not hexadecimal"
    wait
    success
}

function http.test.close_delimited {
    intro "a body that ends when the server closes the connection"
    serve_http 18604 'HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\n\r\nno length given\nsecond line' close-request.txt
    http.get http://127.0.0.1:18604/ >/dev/null
    wait
    assert_equals $'no length given\nsecond line' "$CRUCIBLE_HTTP_BODY" "body"
    success
}

function http.test.big_body {
    intro "a body of one mebibyte"
    local size
    size=1048576
    {
        printf 'HTTP/1.1 200 OK\r\nContent-Length: %s\r\n\r\n' "$size"
        printf '%*s' "$size" '' | tr ' ' 'x'
    } >big-response.bin
    ( timeout 30 nc -N -l 127.0.0.1 18605 <big-response.bin >/dev/null 2>&1 ) &
    wait_for_port tcp 18605
    http.get http://127.0.0.1:18605/ >/dev/null
    assert_equals "0" "$?" "status"
    wait
    assert_equals "$size" "${#CRUCIBLE_HTTP_BODY}" "number of bytes received"
    rm big-response.bin
    success
}

function http.test.error_status {
    intro "http error statuses"
    serve_http 18606 'HTTP/1.1 404 Not Found\r\nContent-Length: 9\r\n\r\nno such it' error-request.txt
    http.request GET http://127.0.0.1:18606/missing ""
    assert_equals "22" "$?" "status of a 404"
    wait
    assert_equals "404" "$CRUCIBLE_HTTP_STATUS" "status code"
    assert_equals "Not Found" "$CRUCIBLE_HTTP_REASON" "reason"
    assert_equals "no such i" "$CRUCIBLE_HTTP_BODY" "the body is still there"
    serve_http 18606 'HTTP/1.1 503\r\nContent-Length: 0\r\n\r\n' error-request.txt
    http.request GET http://127.0.0.1:18606/ ""
    assert_equals "22" "$?" "status of a 503 without reason"
    wait
    assert_equals "" "$CRUCIBLE_HTTP_REASON" "no reason"
    success
}

function http.test.head {
    intro "http.head"
    serve_http 18607 'HTTP/1.1 200 OK\r\nContent-Length: 1000\r\nContent-Type: text/html\r\n\r\n' head-request.txt
    http.head http://127.0.0.1:18607/page
    assert_equals "0" "$?" "status"
    wait
    assert_equals "" "$CRUCIBLE_HTTP_BODY" "a HEAD has no body, whatever the length says"
    assert_equals "1000" "$(http.header content-length)" "headers are there"
    assert_equals "HEAD /page HTTP/1.1" "$(head -n 1 head-request.txt | tr -d '\r')" "method sent"
    success
}

function http.test.no_content {
    intro "statuses without a body"
    serve_http 18608 'HTTP/1.1 204 No Content\r\nContent-Length: 5\r\n\r\nxxxxx' nc-request.txt
    http.get http://127.0.0.1:18608/ >/dev/null
    assert_equals "0" "$?" "204"
    wait
    assert_equals "" "$CRUCIBLE_HTTP_BODY" "no body for 204"
    serve_http 18608 'HTTP/1.1 304 Not Modified\r\n\r\n' nc-request.txt
    http.request GET http://127.0.0.1:18608/ "" 'If-None-Match: "abc"'
    assert_equals "0" "$?" "304"
    wait
    assert_equals "304" "$CRUCIBLE_HTTP_STATUS" "status"
    assert_equals 'If-None-Match: "abc"' "$(grep -i '^if-none-match' nc-request.txt | tr -d '\r')" "header sent"
    success
}

function http.test.post {
    intro "http.post"
    serve_http 18609 'HTTP/1.1 201 Created\r\nContent-Length: 2\r\n\r\nok' post-request.txt
    assert_equals "ok" "$(http.post http://127.0.0.1:18609/items 'name=Ada&city=New%20York')" "body of the response"
    wait
    assert_equals "$(printf 'POST /items HTTP/1.1\r\nHost: 127.0.0.1:18609\r\nUser-Agent: crucible\r\nAccept: */*\r\nConnection: close\r\nContent-Length: 24\r\nContent-Type: application/x-www-form-urlencoded\r\n\r\nname=Ada&city=New%%20York')" "$(cat post-request.txt)" "the request as it was sent"
    serve_http 18609 'HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n' post-request.txt
    http.post http://127.0.0.1:18609/items '{"name":"Ada ünï \\ \"q\""}' 'Content-Type: application/json' >/dev/null
    wait
    grep -qi '^Content-Type: application/json' post-request.txt || fail "The given content type was not sent"
    grep -qi 'x-www-form-urlencoded' post-request.txt && fail "The default content type was sent as well"
    assert_equals '{"name":"Ada ünï \\ \"q\""}' "$(tail -n 1 post-request.txt)" "the body was sent as it is, backslashes included"
    assert_equals "Content-Length: 29" "$(grep -i '^content-length' post-request.txt | tr -d '\r')" "the length counts bytes, not characters"
    serve_http 18609 'HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n' post-request.txt
    http.post http://127.0.0.1:18609/empty '' >/dev/null
    wait
    assert_equals "Content-Length: 0" "$(grep -i '^content-length' post-request.txt | tr -d '\r')" "a post with an empty body says so"
    success
}

function http.test.put_patch_delete {
    intro "http.put, patch and delete"
    local method
    for method in put patch delete; do
        serve_http 18610 'HTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\ndone' verb-request.txt
        if [ "$method" = "delete" ]; then
            assert_equals "done" "$(http.delete http://127.0.0.1:18610/thing)" "$method"
        else
            assert_equals "done" "$("http.$method" http://127.0.0.1:18610/thing 'data')" "$method"
        fi
        wait
        assert_equals "${method^^} /thing HTTP/1.1" "$(head -n 1 verb-request.txt | tr -d '\r')" "method of $method"
    done
    success
}

function http.test.headers {
    intro "headers sent with a request"
    serve_http 18611 'HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n' headers-request.txt
    http.get http://127.0.0.1:18611/ 'Authorization: Bearer abc.def' 'X-Two: 2' 'user-agent: mine' >/dev/null
    wait
    grep -q '^Authorization: Bearer abc.def' headers-request.txt || fail "Authorization was not sent"
    grep -q '^X-Two: 2' headers-request.txt || fail "X-Two was not sent"
    assert_equals "1" "$(grep -ic '^user-agent' headers-request.txt)" "one user agent"
    grep -q '^user-agent: mine' headers-request.txt || fail "The given user agent was not used"
    serve_http 18611 'HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n' headers-request.txt
    CRUCIBLE_HTTP_USER_AGENT="from-env/1.0" http.get http://127.0.0.1:18611/ >/dev/null
    wait
    grep -q '^User-Agent: from-env/1.0' headers-request.txt || fail "CRUCIBLE_HTTP_USER_AGENT was not used"
    serve_http 18611 'HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n' headers-request.txt
    http.get http://127.0.0.1:18611/ 'Host: virtual.example.com' >/dev/null
    wait
    assert_equals "1" "$(grep -ic '^host:' headers-request.txt)" "one host header"
    grep -q '^Host: virtual.example.com' headers-request.txt || fail "The given host was not used"
    success
}

function http.test.header_injection {
    intro "headers and urls that try to add more to the request"
    assert_false "line break in a header" quietly http.get http://127.0.0.1:18699/ $'X-A: b\r\nX-Injected: yes'
    assert_false "line break in a header value" quietly http.get http://127.0.0.1:18699/ $'X-A: b\nX-Injected: yes'
    assert_false "no colon" quietly http.get http://127.0.0.1:18699/ 'not a header'
    assert_false "space in a header name" quietly http.get http://127.0.0.1:18699/ 'Bad Name: x'
    assert_false "line break in the url" quietly http.get $'http://127.0.0.1:18699/\r\nX-Injected: yes'
    assert_false "line break in the method" quietly http.request $'GET\r\nX-Injected: yes' http://127.0.0.1:18699/ ""
    success
}

function http.test.redirect {
    intro "redirects are followed"
    serve_http 18612 'HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:18613/final?from=absolute\r\nContent-Length: 0\r\n\r\n' first-request.txt
    serve_http 18613 'HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\narrive' second-request.txt
    http.request GET http://127.0.0.1:18612/start ""
    assert_equals "0" "$?" "status"
    wait
    assert_equals "200" "$CRUCIBLE_HTTP_STATUS" "status of the final answer"
    assert_equals "arriv" "$CRUCIBLE_HTTP_BODY" "body of the final answer"
    assert_equals "http://127.0.0.1:18613/final?from=absolute" "$CRUCIBLE_HTTP_URL" "the url that was answered"
    assert_equals "GET /final?from=absolute HTTP/1.1" "$(head -n 1 second-request.txt | tr -d '\r')" "the second request"
    assert_equals "Host: 127.0.0.1:18613" "$(grep '^Host' second-request.txt | tr -d '\r')" "with the host of the new location"
    serve_http 18612 'HTTP/1.1 301 Moved\r\nLocation: /moved/here\r\nContent-Length: 0\r\n\r\n' first-request.txt
    ( printf 'HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok' | timeout 20 nc -N -l 127.0.0.1 18612 >second-request.txt 2>/dev/null ) &
    http.get http://127.0.0.1:18612/dir/start >/dev/null 2>&1
    wait
    success
}

function http.test.redirect_changes_method {
    intro "which redirects keep the method and the body"
    # 302: a post becomes a get without body
    serve_http 18614 'HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:18615/\r\nContent-Length: 0\r\n\r\n' first-request.txt
    serve_http 18615 'HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n' second-request.txt
    http.request POST http://127.0.0.1:18614/ 'secret=1'
    wait
    assert_equals "POST / HTTP/1.1" "$(head -n 1 first-request.txt | tr -d '\r')" "first request"
    assert_equals "GET / HTTP/1.1" "$(head -n 1 second-request.txt | tr -d '\r')" "second request after a 302"
    grep -q 'secret' second-request.txt && fail "The body was sent again after a 302"
    # 307: the same request again
    serve_http 18614 'HTTP/1.1 307 Temporary Redirect\r\nLocation: http://127.0.0.1:18615/\r\nContent-Length: 0\r\n\r\n' first-request.txt
    serve_http 18615 'HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n' second-request.txt
    http.request POST http://127.0.0.1:18614/ 'secret=1'
    wait
    assert_equals "POST / HTTP/1.1" "$(head -n 1 second-request.txt | tr -d '\r')" "second request after a 307"
    assert_equals "secret=1" "$(tail -n 1 second-request.txt)" "body after a 307"
    # a head stays a head
    serve_http 18614 'HTTP/1.1 301 Moved\r\nLocation: http://127.0.0.1:18615/\r\nContent-Length: 0\r\n\r\n' first-request.txt
    serve_http 18615 'HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n' second-request.txt
    http.request HEAD http://127.0.0.1:18614/ ""
    wait
    assert_equals "HEAD / HTTP/1.1" "$(head -n 1 second-request.txt | tr -d '\r')" "second request of a head"
    success
}

function http.test.redirect_limit {
    intro "too many redirects, and not following at all"
    serve_http 18616 'HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:18617/\r\nContent-Length: 0\r\n\r\n' r1.txt
    serve_http 18617 'HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:18618/\r\nContent-Length: 0\r\n\r\n' r2.txt
    serve_http 18618 'HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:18619/\r\nContent-Length: 0\r\n\r\n' r3.txt
    CRUCIBLE_HTTP_MAX_REDIRECTS=2 http.request GET http://127.0.0.1:18616/ "" >/dev/null 2>&1
    assert_equals "1" "$?" "two redirects are allowed, the third is an error"
    wait
    serve_http 18616 'HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:18617/\r\nContent-Length: 0\r\n\r\n' r1.txt
    CRUCIBLE_HTTP_MAX_REDIRECTS=0 http.request GET http://127.0.0.1:18616/ ""
    assert_equals "0" "$?" "not following is not an error"
    wait
    assert_equals "302" "$CRUCIBLE_HTTP_STATUS" "the redirect itself is the answer"
    assert_equals "http://127.0.0.1:18617/" "$(http.header location)" "with its location"
    success
}

function http.test.unsupported_urls {
    intro "urls that cannot be requested"
    local output
    output="$(http.get https://example.com/ 2>&1)"
    assert_equals "1" "$?" "https"
    [[ "$output" == *TLS* ]] || fail "The reason for refusing https should be given: $output"
    assert_false "ftp" quietly http.get ftp://example.com/
    assert_false "no url" quietly http.get
    assert_false "post without body" quietly http.post http://127.0.0.1:18699/
    success
}

function http.test.refused {
    intro "nothing listens on the port"
    local output
    output="$(http.get http://127.0.0.1:18698/ 2>&1)"
    assert_equals "1" "$?" "status"
    [[ "$output" == *"Could not connect"* ]] || fail "The failure should be reported: $output"
    success
}

function http.test.silent_server {
    intro "a server that never answers"
    local start
    ( sleep 10 | timeout 20 nc -l 127.0.0.1 18620 >/dev/null 2>&1 ) &
    wait_for_port tcp 18620
    start=$SECONDS
    CRUCIBLE_HTTP_TIMEOUT=1 http.get http://127.0.0.1:18620/ >/dev/null 2>&1
    assert_equals "1" "$?" "status"
    test $((SECONDS - start)) -le 4 || fail "Took $((SECONDS - start)) seconds with a timeout of 1"
    kill %% 2>/dev/null
    wait 2>/dev/null
    success
}

function http.test.truncated {
    intro "a server that stops halfway"
    serve_http 18621 'HTTP/1.1 200 OK\r\nContent-Length: 100\r\n\r\nonly ten b' truncated-request.txt
    http.get http://127.0.0.1:18621/ >/dev/null 2>&1
    wait
    assert_equals "only ten b" "$CRUCIBLE_HTTP_BODY" "what arrived is there"
    serve_http 18621 '' truncated-request.txt
    http.get http://127.0.0.1:18621/ >/dev/null 2>&1
    assert_equals "1" "$?" "no answer at all"
    wait
    serve_http 18621 'HTTP/1.1 200 OK\r\nContent-Length: 5\r\nX-Half: yes' truncated-request.txt
    http.get http://127.0.0.1:18621/ >/dev/null 2>&1
    assert_equals "1" "$?" "headers that stop halfway"
    wait
    success
}

function http.test.not_http {
    intro "an answer that is not HTTP"
    serve_http 18622 'SSH-2.0-OpenSSH_9.2\r\n' garbage-request.txt
    http.get http://127.0.0.1:18622/ >/dev/null 2>&1
    assert_equals "1" "$?" "status"
    wait
    serve_http 18622 'HTTP/1.1 20 OK\r\n\r\n' garbage-request.txt
    http.get http://127.0.0.1:18622/ >/dev/null 2>&1
    assert_equals "1" "$?" "status code of two digits"
    wait
    success
}

function http.test.continue_is_skipped {
    intro "informational responses before the real one"
    serve_http 18623 'HTTP/1.1 100 Continue\r\n\r\nHTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\ndone' continue-request.txt
    http.get http://127.0.0.1:18623/ >/dev/null
    wait
    assert_equals "200" "$CRUCIBLE_HTTP_STATUS" "status"
    assert_equals "done" "$CRUCIBLE_HTTP_BODY" "body"
    success
}

echo "Testing http/http"

for test in "${tests[@]}"; do
    "$test"
done

teardown
