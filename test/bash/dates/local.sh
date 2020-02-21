#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/dates/local -p
cd tmp/dates/local || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require dates/local

declare -a tests

tests=("dates.dates.local.now")
tests+=("dates.dates.local.now.timestamp")
tests+=("dates.dates.local.rfc3339.ns")
tests+=("dates.dates.local.rfc3339.seconds")
tests+=("dates.dates.local.rfc3339.date")
tests+=("dates.dates.local.email")
tests+=("dates.dates.local.iso8601.ns")
tests+=("dates.dates.local.iso8601.seconds")
tests+=("dates.dates.local.iso8601.minutes")
tests+=("dates.dates.local.iso8601.hours")
tests+=("dates.dates.local.iso8601.date")

function dates.dates.local.now {
    intro "dates.dates.local.now"
    
    
    date=$(dates.local.now --date='@0')
    test "$date" = "Thu Jan  1 00:00:00 UTC 1970" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.local.now.timestamp {
    intro "dates.dates.local.now.timestamp"
    
    
    date=$(dates.local.now.timestamp --date='@0')
    test "$date" = "0" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.local.rfc3339.ns {
    intro "dates.dates.local.rfc3339.ns"
    
    
    date=$(dates.local.rfc3339.ns --date='@0')
    test "$date" = "1970-01-01 00:00:00.000000000+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.local.rfc3339.seconds {
    intro "dates.dates.local.rfc3339.seconds"
    
    
    date=$(dates.local.rfc3339.seconds --date='@0')
    test "$date" = "1970-01-01 00:00:00+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.local.rfc3339.date {
    intro "dates.dates.local.rfc3339.date"
    
    
    date=$(dates.local.rfc3339.date --date='@0')
    test "$date" = "1970-01-01" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.local.email {
    intro "dates.dates.local.email"
    
    
    date=$(dates.local.email --date='@0')
    test "$date" = "Thu, 01 Jan 1970 00:00:00 +0000" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.local.iso8601.ns {
    intro "dates.dates.local.iso8601.ns"
    
    
    date=$(dates.local.iso8601.ns --date='@0')
    test "$date" = "1970-01-01T00:00:00,000000000+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.local.iso8601.seconds {
    intro "dates.dates.local.iso8601.seconds"
    
    
    date=$(dates.local.iso8601.seconds --date='@0')
    test "$date" = "1970-01-01T00:00:00+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.local.iso8601.minutes {
    intro "dates.dates.local.iso8601.minutes"
    
    
    date=$(dates.local.iso8601.minutes --date='@0')
    test "$date" = "1970-01-01T00:00+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.local.iso8601.hours {
    intro "dates.dates.local.iso8601.hours"
    
    
    date=$(dates.local.iso8601.hours --date='@0')
    test "$date" = "1970-01-01T00+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.local.iso8601.date {
    intro "dates.dates.local.iso8601.date"
    
    
    date=$(dates.local.iso8601.date --date='@0')
    test "$date" = "1970-01-01" || fail "Date returned did not contain correct format: $date"
    
    success
}

echo "Testing dates/local"

for test in "${tests[@]}"
do
    "$test"
done

teardown