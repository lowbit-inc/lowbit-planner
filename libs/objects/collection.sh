#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function collection_add() {

  log_print debug "Starting Collection Add"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message collection_add
  fi

  this_collection_name="$1" ; log_print debug "Collection name: ${this_collection_name}"

  generic_add "collections" "name" "'${this_collection_name}'" "${this_collection_name}"

}

function collection_delete() {

  log_print debug "Starting Collection Delete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message collection
  fi

  this_collection_id="$1" ; log_print debug "Collection ID: ${this_collection_id}"

  validate_database_id collections "${this_collection_id}"

  this_collection_name=$(database_run csv "SELECT name FROM collections WHERE id = ${this_collection_id};")

  generic_delete "collections" "id" "${this_collection_id}" "${this_collection_name}"

}

function collection_edit() {

  log_print debug "Starting Collection Edit"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message collection_edit
  fi

  this_collection_id="$1" ; log_print debug "Collection ID: ${this_collection_id}" ; shift

  validate_database_id collections "${this_collection_id}"

  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property collections id "${this_collection_id}" name "'${1}'"
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

function collection_list() {

  log_print debug "Starting Collection List"

  generic_list collections_view

}

function collection_search() {

  log_print debug "Starting Collection Search"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message collection
  fi

  this_collection_pattern="$1" ; log_print debug "Search pattern: ${this_collection_pattern}"

  database_run box "SELECT * FROM collections_view WHERE name LIKE '%${this_collection_pattern}%'"

}

function collection_main() {

  log_print debug "Starting Collection Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message collection
  fi

  case "${user_arg}" in
    "add")
      collection_add "$@"
      ;;
    "delete")
      collection_delete "$@"
      ;;
    "edit")
      collection_edit "$@"
      ;;
    "help")
      help_get_message collection
      ;;
    "list")
      collection_list
      ;;
    "search")
      collection_search "$@"
      ;;
    *)
      help_get_message collection
      ;;
  esac

}
