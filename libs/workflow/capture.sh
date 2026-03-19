#!/bin/bash

##############
# Properties #
##############

###########
# Methods #
###########

function capture_main() {

  log_print debug "Starting capture workflow"

  if [[ "$1" ]]; then
    inbox_add "$@"
  else
    log_print warn "Missing IDEA to capture"
  fi
}