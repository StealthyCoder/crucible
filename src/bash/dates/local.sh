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