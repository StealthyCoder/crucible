#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/dates/utc -p
cd tmp/dates/utc || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require dates/utc

declare -a tests

tests=("dates.dates.utc.now")
tests+=("dates.dates.utc.now.timestamp")
tests+=("dates.dates.utc.rfc3339.ns")
tests+=("dates.dates.utc.rfc3339.seconds")
tests+=("dates.dates.utc.rfc3339.date")
tests+=("dates.dates.utc.email")
tests+=("dates.dates.utc.iso8601.ns")
tests+=("dates.dates.utc.iso8601.seconds")
tests+=("dates.dates.utc.iso8601.minutes")
tests+=("dates.dates.utc.iso8601.hours")
tests+=("dates.dates.utc.iso8601.date")

function dates.dates.utc.now {
    intro "dates.dates.utc.now"
    
    
    date=$(dates.utc.now --date='@0')
    test "$date" = "Thu Jan  1 00:00:00 UTC 1970" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.utc.now.timestamp {
    intro "dates.dates.utc.now.timestamp"
    
    
    date=$(dates.utc.now.timestamp --date='@0')
    test "$date" = "0" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.utc.rfc3339.ns {
    intro "dates.dates.utc.rfc3339.ns"
    
    
    date=$(dates.utc.rfc3339.ns --date='@0')
    test "$date" = "1970-01-01 00:00:00.000000000+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.utc.rfc3339.seconds {
    intro "dates.dates.utc.rfc3339.seconds"
    
    
    date=$(dates.utc.rfc3339.seconds --date='@0')
    test "$date" = "1970-01-01 00:00:00+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.utc.rfc3339.date {
    intro "dates.dates.utc.rfc3339.date"
    
    
    date=$(dates.utc.rfc3339.date --date='@0')
    test "$date" = "1970-01-01" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.utc.email {
    intro "dates.dates.utc.email"
    
    
    date=$(dates.utc.email --date='@0')
    test "$date" = "Thu, 01 Jan 1970 00:00:00 +0000" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.utc.iso8601.ns {
    intro "dates.dates.utc.iso8601.ns"
    
    
    date=$(dates.utc.iso8601.ns --date='@0')
    test "$date" = "1970-01-01T00:00:00,000000000+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.utc.iso8601.seconds {
    intro "dates.dates.utc.iso8601.seconds"
    
    
    date=$(dates.utc.iso8601.seconds --date='@0')
    test "$date" = "1970-01-01T00:00:00+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.utc.iso8601.minutes {
    intro "dates.dates.utc.iso8601.minutes"
    
    
    date=$(dates.utc.iso8601.minutes --date='@0')
    test "$date" = "1970-01-01T00:00+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.utc.iso8601.hours {
    intro "dates.dates.utc.iso8601.hours"
    
    
    date=$(dates.utc.iso8601.hours --date='@0')
    test "$date" = "1970-01-01T00+00:00" || fail "Date returned did not contain correct format: $date"
    
    success
}

function dates.dates.utc.iso8601.date {
    intro "dates.dates.utc.iso8601.date"
    
    
    date=$(dates.utc.iso8601.date --date='@0')
    test "$date" = "1970-01-01" || fail "Date returned did not contain correct format: $date"
    
    success
}

echo "Testing dates/utc"

for test in "${tests[@]}"
do
    "$test"
done

teardown