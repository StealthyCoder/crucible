#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require maps/maps

function __setup_global_registry {
  if ! declare -p CRUCIBLE_CLASS_REGISTRY &>>/dev/null; then
    declare -Agx CRUCIBLE_CLASS_REGISTRY=()
  fi
  if ! declare -p CRUCIBLE_INSTANCE_REGISTRY &>>/dev/null; then
    declare -Agx CRUCIBLE_INSTANCE_REGISTRY=()
  fi
}

function __add_to_global_class_registry {
  __verify_nr_args "$#" 2 add_to_global_class_registry
  local key value
  key="$1"
  value="$2"
  maps.put CRUCIBLE_CLASS_REGISTRY "$key" "$value"
}

function __add_to_global_instance_registry {
  __verify_nr_args "$#" 2 add_to_global_instance_registry
  local key value
  key="$1"
  value="$2"
  maps.put CRUCIBLE_INSTANCE_REGISTRY "$key" "$value"
}

__setup_global_registry
