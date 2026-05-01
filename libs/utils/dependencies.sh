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
    # Checking the dependency
    which "${dependency}" > /dev/null 2>&1 ; this_rc=$?

    # Validating
    if [[ $this_rc -ne 0 ]] ; then
      echo "Error: dependency '${dependency}' not found."
      exit 1
    fi
  done
}

##########
# Script #
##########

dependencies_check