#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

function dates.local.now {
    if [ -z "$1" ]
    then
        date
    else
        date "$1"
    fi
    
}

function dates.local.now.timestamp {
    if [ -z "$1" ]
    then
        date +%s
    else
        date +%s "$1"
    fi
    
}

function dates.local.rfc3339.ns {
    if [ -z "$1" ]
    then
        date --rfc-3339=ns
    else
        date --rfc-3339=ns "$1"
    fi
    
}

function dates.local.rfc3339.seconds {
    if [ -z "$1" ]
    then
        date --rfc-3339=seconds
    else
        date --rfc-3339=seconds "$1"
    fi
    
}

function dates.local.rfc3339.date {
    if [ -z "$1" ]
    then
        date --rfc-3339=date
    else
        date --rfc-3339=date "$1"
    fi
    
}

function dates.local.email {
    if [ -z "$1" ]
    then
        date --rfc-email
    else
        date --rfc-email "$1"
    fi
    
}

function dates.local.iso8601.ns {
    if [ -z "$1" ]
    then
        date --iso-8601=ns
    else
        date --iso-8601=ns "$1"
    fi
    
}

function dates.local.iso8601.seconds {
    if [ -z "$1" ]
    then
        date --iso-8601=seconds
    else
        date --iso-8601=seconds "$1"
    fi
    
}

function dates.local.iso8601.minutes {
    if [ -z "$1" ]
    then
        date --iso-8601=minutes
    else
        date --iso-8601=minutes "$1"
    fi
    
}

function dates.local.iso8601.hours {
    if [ -z "$1" ]
    then
        date --iso-8601=hours
    else
        date --iso-8601=hours "$1"
    fi
    
}

function dates.local.iso8601.date {
    if [ -z "$1" ]
    then
        date --iso-8601=date
    else
        date --iso-8601=date "$1"
    fi
    
}