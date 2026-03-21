#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function validate_database_id() {
  this_table="$1"
  this_id="$2"    && validate_number "${this_id}"

  this_returned_id=$(database_run csv "SELECT id FROM $this_table WHERE id = $this_id;")

  if [[ $this_returned_id -eq $this_id ]]; then
    log_print debug "Validation: ID $this_id exists in table $this_table"
  else
    log_print error "ID $this_id not found in $this_table"
  fi
}

function validate_number() {
  this_number="$1"

  if [[ "${this_number}" =~ ^[0-9]+$ ]]; then
    log_print debug "Validation: Value $this_id is a number $this_table"
  else
    log_print error "\'$this_id\' is not a number"
  fi

}