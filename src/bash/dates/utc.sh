#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

function dates.utc.now {
    date -u
}

function dates.utc.now.timestamp {
    date -u +%s
}

function dates.utc.rfc3339.ns {
    date -u --rfc-3339=ns
}

function dates.utc.rfc3339.seconds {
    date -u --rfc-3339=seconds
}

function dates.utc.rfc3339.date {
    date -u --rfc-3339=date
}

function dates.utc.email {
    date -u --rfc-email
}

function dates.utc.iso8601.ns {
    date -u --iso-8601=ns
}

function dates.utc.is8601.seconds {
    date -u --iso-8601=seconds
}

function dates.utc.iso8601.minutes {
    date -u --iso-8601=minutes
}

function dates.utc.iso8601.hours {
    date -u --iso-8601=hours
}

function dates.utc.iso8601.date {
    date -u --iso-8601=date
}