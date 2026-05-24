#!/bin/bash

##############
# Properties #
##############

dependencies_list="
  sqlite3
"

###########
# Methods #
###########

function dependencies_check() {
  for dependency in $dependencies_list; do
    if ! command -v "${dependency}" > /dev/null 2>&1; then
      echo "Error: dependency '${dependency}' not found. Please install it before running ${system_basename}."
      exit 1
    fi
  done
}

##########
# Script #
##########

dependencies_check