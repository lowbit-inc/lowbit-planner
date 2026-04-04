#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function area_add() {

  log_print debug "Starting Area Add"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message area_add
  fi

  # Getting positional arg
  this_area_name="$1" ; log_print debug "Area name: ${this_area_name}" ; shift

  # Getting optional flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--description")
        shift
        if [[ "${1}" ]] ; then
          this_area_description="${1}"
          log_print debug "Area description: ${this_area_description}"
        else
          log_print error "Missing value for description"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

  # Build fields/values based on what was provided
  if [[ "${this_area_description}" ]]; then
    generic_add "areas" "name, description" "'${this_area_name}', '${this_area_description}'" "${this_area_name}"
  else
    generic_add "areas" "name" "'${this_area_name}'" "${this_area_name}"
  fi

}

function area_delete() {

  log_print debug "Starting Area Delete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message area_delete
  fi

  # Getting positional arg
  this_area_name="$1" ; log_print debug "Area name: ${this_area_name}"

  # Verify area exists
  this_area_id=$(database_run csv "SELECT id FROM areas WHERE name = '${this_area_name}';")
  if [[ ! "${this_area_id}" ]]; then
    log_print error "Area '${this_area_name}' not found"
  fi

  # Confirmation
  log_print user "Are you sure you want to delete area '${this_area_name}'?"

  # Execution
  database_run box "DELETE FROM areas WHERE name = '${this_area_name}';"

  # Confirmation message
  log_print info "Area '${this_area_name}' deleted"

}

function area_list() {

  log_print debug "Starting Area List"

  generic_list areas_view

}

function area_edit() {

  log_print debug "Starting Area Edit"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message area_edit
  fi

  # Getting positional arg
  this_area_name="$1" ; log_print debug "Area name: ${this_area_name}" ; shift

  # Verify area exists
  this_area_id=$(database_run csv "SELECT id FROM areas WHERE name = '${this_area_name}';")
  if [[ ! "${this_area_id}" ]]; then
    log_print error "Area '${this_area_name}' not found"
  fi

  # Getting optional flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          this_area_new_name="${1}"
          log_print debug "New area name: ${this_area_new_name}"
          generic_set_property areas name "'${this_area_name}'" name "'${this_area_new_name}'"
          this_area_name="${this_area_new_name}"
        else
          log_print error "Missing value for name"
        fi
        ;;
      "--description")
        shift
        if [[ "${1}" ]] ; then
          this_area_new_description="${1}"
          log_print debug "New area description: ${this_area_new_description}"
          generic_set_property areas name "'${this_area_name}'" description "'${this_area_new_description}'"
        else
          log_print error "Missing value for description"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

}

function area_main() {

  log_print debug "Starting Area Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message area
  fi

  case "${user_arg}" in
    "add")
      area_add "$@"
      ;;
    "delete")
      area_delete "$@"
      ;;
    "edit")
      area_edit "$@"
      ;;
    "list")
      area_list
      ;;
    "help")
      help_get_message area
      ;;
    *)
      help_get_message area
      ;;
  esac

}
