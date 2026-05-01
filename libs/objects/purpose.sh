#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function purpose_add() {

  log_print debug "Starting Purpose Add"

  # Scope all working vars to this call so repeated invocations (e.g. from the
  # clarify TUI) cannot leak optional flag values from a previous call.
  local this_purpose_name=""
  local this_purpose_description=""
  local this_arg=""
  local this_fields=""
  local this_values=""

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message purpose_add
  fi

  # Getting positional arg
  this_purpose_name="$1" ; log_print debug "Purpose name: ${this_purpose_name}" ; shift

  # Getting flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--description")
        shift
        if [[ "${1}" ]] ; then
          this_purpose_description="${1}"
          log_print debug "Description: ${this_purpose_description}"
        else
          log_print error "Missing value for --description"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

  # Build fields and values for INSERT
  this_fields="name"
  this_values="'${this_purpose_name}'"

  if [[ "${this_purpose_description}" ]]; then
    this_fields="${this_fields}, description"
    this_values="${this_values}, '${this_purpose_description}'"
  fi

  generic_add "purposes" "${this_fields}" "${this_values}" "${this_purpose_name}"

}

function purpose_delete() {

  log_print debug "Starting Purpose Delete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message purpose
  fi

  # Getting positional arg
  this_purpose_id="$1" ; log_print debug "Purpose ID: ${this_purpose_id}"

  # Validate ID
  validate_database_id purposes "${this_purpose_id}"

  # Fetch name for confirmation
  this_purpose_name=$(database_run csv "SELECT name FROM purposes WHERE id = ${this_purpose_id};")

  generic_delete "purposes" "id" "${this_purpose_id}" "${this_purpose_name}"

}

function purpose_edit() {

  log_print debug "Starting Purpose Edit"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message purpose_edit
  fi

  # Getting positional arg
  this_purpose_id="$1" ; log_print debug "Purpose ID: ${this_purpose_id}" ; shift

  # Validate ID
  validate_database_id purposes "${this_purpose_id}"

  # Getting optional flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property purposes id "${this_purpose_id}" name "'${1}'"
        else
          log_print error "Missing value for --name"
        fi
        ;;
      "--description")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property purposes id "${this_purpose_id}" description "'${1}'"
        else
          log_print error "Missing value for --description"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

}

function purpose_list() {

  log_print debug "Starting Purpose List"

  generic_list purposes_view

}

function purpose_search() {

  log_print debug "Starting Purpose Search"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message purpose
  fi

  this_purpose_pattern="$1" ; log_print debug "Search pattern: ${this_purpose_pattern}"

  database_run box "SELECT * FROM purposes_view WHERE name LIKE '%${this_purpose_pattern}%'"

}

function purpose_main() {

  log_print debug "Starting Purpose Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message purpose
  fi

  case "${user_arg}" in
    "add")
      purpose_add "$@"
      ;;
    "delete")
      purpose_delete "$@"
      ;;
    "edit")
      purpose_edit "$@"
      ;;
    "help")
      help_get_message purpose
      ;;
    "list")
      purpose_list
      ;;
    "search")
      purpose_search "$@"
      ;;
    *)
      help_get_message purpose
      ;;
  esac

}
