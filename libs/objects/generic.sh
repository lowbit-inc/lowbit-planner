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

function generic_delete() {
  # Getting args
  this_table="${1}"
  this_field="${2}"
  this_value="${3}"
  this_identity="${4}"

  # Confirmation
  log_print user "Delete ${color_green}${this_identity}${color_reset} from ${this_table}?"

  # Generating database query
  this_database_query="DELETE FROM ${this_table} WHERE ${this_field} = ${this_value};"

  # Executing query
  database_run box "${this_database_query}" ; database_run_rc=$?
  if [[ $database_run_rc -eq 0 ]]; then
    log_print info "Deleted ${color_green}${this_identity}${color_reset} from ${this_table}"
  else
    log_print error "Failed to delete ${this_identity} from ${this_table}"
  fi

}

function generic_list() {
  this_table="$1"
  this_filter="${2}"

  if [[ "${this_filter}" ]]; then
    database_run box "SELECT * FROM ${this_table} WHERE ${this_filter}"
  else
    database_run box "SELECT * FROM ${this_table}"
  fi
}

function generic_build_status_filter() {
  # Usage: generic_build_status_filter VALUE
  # Returns a SQL WHERE clause fragment for status filtering
  # Values: "Pending", "In Progress", "Done", "all"
  # Default (no value): status != 'Done'
  local this_status_value="${1}"

  case "${this_status_value}" in
    "Pending")
      echo "status = 'Pending'"
      ;;
    "In Progress")
      echo "status = 'In Progress'"
      ;;
    "Done")
      echo "status = 'Done'"
      ;;
    "all")
      echo ""
      ;;
    *)
      echo "status != 'Done'"
      ;;
  esac
}

function generic_set_status() {
  # Usage: generic_set_status TABLE ID STATUS
  this_table="${1}"
  this_id="${2}"
  this_status="${3}"

  # Fetch current status and name
  this_identity=$(database_run csv "SELECT name FROM ${this_table} WHERE id = ${this_id};")
  this_current_status=$(database_run csv "SELECT status FROM ${this_table} WHERE id = ${this_id};")

  if [[ "${this_current_status}" == "Done" ]]; then
    log_print error "'${this_identity}' is already completed and cannot be changed"
  fi

  generic_set_property "${this_table}" id "${this_id}" status "'${this_status}'" "${this_identity}"
}

function generic_complete() {
  # Usage: generic_complete TABLE ID
  this_table="${1}"
  this_id="${2}"

  # Fetch current status and name
  this_identity=$(database_run csv "SELECT name FROM ${this_table} WHERE id = ${this_id};")
  this_current_status=$(database_run csv "SELECT status FROM ${this_table} WHERE id = ${this_id};")

  if [[ "${this_current_status}" == "Done" ]]; then
    log_print error "'${this_identity}' is already completed"
  fi

  # Confirmation
  log_print user "Mark ${color_green}${this_identity}${color_reset} as complete?"

  # Resolve timestamp once
  this_completed_at=$(date '+%Y-%m-%d %H:%M:%S')

  # Set status and completed_at
  generic_set_property "${this_table}" id "${this_id}" status "'Done'" "${this_identity}"
  generic_set_property "${this_table}" id "${this_id}" completed_at "'${this_completed_at}'" "${this_identity}"
}

function generic_set_property() {
  # Getting args
  this_table="$1"
  this_source_field="$2"
  this_source_value="$3"
  this_target_field="$4"
  this_target_value="$5"
  this_display_name="${6:-${this_source_value}}"

  # Generating database query
  this_database_query="UPDATE ${this_table} SET ${this_target_field} = ${this_target_value} WHERE ${this_source_field} = ${this_source_value}"

  # Executing query
  database_run box "${this_database_query}" ; database_run_rc=$?
  if [[ $database_run_rc -eq 0 ]]; then
    log_print info "Updated ${color_underline}${this_target_field}${color_reset} of ${color_green}${this_display_name}${color_reset} to ${color_green}${this_target_value}${color_reset}"
  else
    log_print error "Failed to set ${this_target_field} of ${this_display_name} to ${this_target_value}"
  fi
}