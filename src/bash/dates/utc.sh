#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.2.5
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1596058258
### CRUCIBLE META DATA ###

function dates.utc.now {
    if [ -z "$1" ]
    then
        date -u
    else
        date -u "$1"
    fi
    
}

function dates.utc.now.timestamp {
    if [ -z "$1" ]
    then
        date -u +%s
    else
        date -u +%s "$1"
    fi
}

function dates.utc.rfc3339.ns {
    if [ -z "$1" ]
    then
        date -u --rfc-3339=ns
    else
        date -u --rfc-3339=ns "$1"
    fi
}

function dates.utc.rfc3339.seconds {
    if [ -z "$1" ]
    then
        date -u --rfc-3339=seconds
    else
        date -u --rfc-3339=seconds "$1"
    fi
}

function dates.utc.rfc3339.date {
    if [ -z "$1" ]
    then
        date -u --rfc-3339=date
    else
        date -u --rfc-3339=date "$1"
    fi    
}

function dates.utc.email {
    if [ -z "$1" ]
    then
        date -u --rfc-email    
    else
        date -u --rfc-email "$1"
    fi
}

function dates.utc.iso8601.ns {
    if [ -z "$1" ]
    then
        date -u --iso-8601=ns
    else
        date -u --iso-8601=ns "$1"
    fi
}

function dates.utc.iso8601.seconds {
    if [ -z "$1" ]
    then
        date -u --iso-8601=seconds
    else
        date -u --iso-8601=seconds "$1"
    fi
}

function dates.utc.iso8601.minutes {
    if [ -z "$1" ]
    then
        date -u --iso-8601=minutes
    else
        date -u --iso-8601=minutes "$1"
    fi
}

function dates.utc.iso8601.hours {
    if [ -z "$1" ]
    then
        date -u --iso-8601=hours
    else
        date -u --iso-8601=hours "$1"
    fi
}

function dates.utc.iso8601.date {
    if [ -z "$1" ]
    then
        date -u --iso-8601=date
    else
        date -u --iso-8601=date "$1"
    fi
} 