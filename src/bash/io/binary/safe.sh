#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require io/binary/binary

function binary.read_file {
  __verify_nr_args "$#" 1 binary.read_file
  local target
  target="$1"
  if [ -f "$target" ]
  then
    if __command_exists "file"
    then
        if binary.is_printable "$target"
        then
            cat "$target"
        fi
    fi
  fi
}