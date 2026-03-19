#!/bin/bash

##############
# Properties #
##############

###########
# Methods #
###########

function validate_database_id() {
  this_table=$1
  this_id=$2

  this_returned_id=$(database_run csv "SELECT id FROM $this_table WHERE id = $this_id;")

  if [[ $this_returned_id -eq $this_id ]]; then
    log_print debug "Validation: ID $this_id exists in table $this_table"
  else
    log_print error "ID $this_id not found in table $this_table"
  fi
}