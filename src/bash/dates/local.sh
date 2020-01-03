#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

function dates.local.now {
    date
}

function dates.local.now.timestamp {
    date +%s
}

function dates.local.rfc3339.ns {
    date --rfc-3339=ns
}

function dates.local.rfc3339.seconds {
    date --rfc-3339=seconds
}

function dates.local.rfc3339.date {
    date --rfc-3339=date
}

function dates.local.email {
    date --rfc-email
}

function dates.local.iso8601.ns {
    date --iso-8601=ns
}

function dates.local.is8601.seconds {
    date --iso-8601=seconds
}

function dates.local.iso8601.minutes {
    date --iso-8601=minutes
}

function dates.local.iso8601.hours {
    date --iso-8601=hours
}

function dates.local.iso8601.date {
    date --iso-8601=date
}