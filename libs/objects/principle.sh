#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function principle_add() {

  log_print debug "Starting Principle Add"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message principle_add
  fi

  # Getting positional arg
  this_principle_name="$1" ; log_print debug "Principle name: ${this_principle_name}"

  generic_add "principles" "name" "'${this_principle_name}'" "${this_principle_name}"

}

function principle_delete() {

  log_print debug "Starting Principle Delete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message principle
  fi

  # Getting positional arg
  this_principle_id="$1" ; log_print debug "Principle ID: ${this_principle_id}"

  # Validate ID
  validate_database_id principles "${this_principle_id}"

  # Fetch name for confirmation
  this_principle_name=$(database_run csv "SELECT name FROM principles WHERE id = ${this_principle_id};")

  generic_delete "principles" "id" "${this_principle_id}" "${this_principle_name}"

}

function principle_edit() {

  log_print debug "Starting Principle Edit"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message principle_edit
  fi

  # Getting positional arg
  this_principle_id="$1" ; log_print debug "Principle ID: ${this_principle_id}" ; shift

  # Validate ID
  validate_database_id principles "${this_principle_id}"

  # Getting optional flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property principles id "${this_principle_id}" name "'${1}'"
        else
          log_print error "Missing value for --name"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

}

function principle_list() {

  log_print debug "Starting Principle List"

  generic_list principles_view

}

function principle_search() {

  log_print debug "Starting Principle Search"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message principle
  fi

  this_principle_pattern="$1" ; log_print debug "Search pattern: ${this_principle_pattern}"

  database_run box "SELECT * FROM principles_view WHERE name LIKE '%${this_principle_pattern}%'"

}

function principle_main() {

  log_print debug "Starting Principle Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message principle
  fi

  case "${user_arg}" in
    "add")
      principle_add "$@"
      ;;
    "delete")
      principle_delete "$@"
      ;;
    "edit")
      principle_edit "$@"
      ;;
    "help")
      help_get_message principle
      ;;
    "list")
      principle_list
      ;;
    "search")
      principle_search "$@"
      ;;
    *)
      help_get_message principle
      ;;
  esac

}
