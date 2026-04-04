#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

# generic_add_2
#
# table
# positional field
# positional format
# positional value
# required fields
# required formats
# required values
# optional fields
# optional formats
# optional values


function generic_add() {
  # Getting args
  this_table="${1}"
  this_fields="${2}"
  this_values="${3}"
  this_identity="${4}"

  # Generating database query
  this_database_query="INSERT INTO ${this_table} (${this_fields}) VALUES (${this_values});"

  # Executing query
  database_run box "${this_database_query}" ; database_run_rc=$?
  if [[ $database_run_rc -eq 0 ]]; then
    log_print info "Item added to ${this_table} (${color_green}${this_identity}${color_reset})"
  else
    log_print error "Failed to add item to ${this_table}"
  fi

}

function generic_list() {
  this_table="$1"

  database_run box "SELECT * FROM ${this_table}"
}

function generic_set_property() {
  # Getting args
  this_table="$1"
  this_source_field="$2"
  this_source_value="$3"
  this_target_field="$4"
  this_target_value="$5"

  # Generating database query
  this_database_query="UPDATE ${this_table} SET ${this_target_field} = ${this_target_value} WHERE ${this_source_field} = ${this_source_value}"

  # Executing query
  database_run box "${this_database_query}" ; database_run_rc=$?
  if [[ $database_run_rc -eq 0 ]]; then
    log_print info "Updated ${color_underline}${this_target_field}${color_reset} of ${color_underline}${this_source_value}${color_reset} to ${color_green}${this_target_value}${color_reset}"
  else
    log_print error "Failed to set ${this_target_field} of ${this_source_value} to ${this_target_value}"
  fi
}