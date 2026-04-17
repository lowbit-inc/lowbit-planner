#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function item_add() {

  log_print debug "Starting Item Add"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message item_add
  fi

  # Getting positional arg
  this_item_name="$1" ; log_print debug "Item name: ${this_item_name}" ; shift

  # Getting required flag
  this_item_collection_name=""

  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--collection")
        shift
        if [[ "${1}" ]] ; then
          this_item_collection_name="${1}"
          log_print debug "Collection name: ${this_item_collection_name}"
        else
          log_print error "Missing value for --collection"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

  if [[ ! "${this_item_collection_name}" ]]; then
    log_print error "Missing required flag --collection COLLECTION_NAME"
  fi

  # Resolve collection name to ID
  this_item_collection_id=$(database_run csv "SELECT id FROM collections WHERE name = '${this_item_collection_name}';")
  if [[ ! "${this_item_collection_id}" ]]; then
    log_print error "Collection '${this_item_collection_name}' not found"
  fi

  generic_add "collection_items" "name, collection_id" "'${this_item_name}', ${this_item_collection_id}" "${this_item_name}"

}

function item_delete() {

  log_print debug "Starting Item Delete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message item
  fi

  this_item_id="$1" ; log_print debug "Item ID: ${this_item_id}"

  validate_database_id collection_items "${this_item_id}"

  this_item_name=$(database_run csv "SELECT name FROM collection_items WHERE id = ${this_item_id};")

  generic_delete "collection_items" "id" "${this_item_id}" "${this_item_name}"

}

function item_edit() {

  log_print debug "Starting Item Edit"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message item_edit
  fi

  this_item_id="$1" ; log_print debug "Item ID: ${this_item_id}" ; shift

  validate_database_id collection_items "${this_item_id}"

  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property collection_items id "${this_item_id}" name "'${1}'"
        else
          log_print error "Missing value for --name"
        fi
        ;;
      "--collection")
        shift
        if [[ "${1}" ]] ; then
          this_edit_collection_id=$(database_run csv "SELECT id FROM collections WHERE name = '${1}';")
          if [[ ! "${this_edit_collection_id}" ]]; then
            log_print error "Collection '${1}' not found"
          fi
          generic_set_property collection_items id "${this_item_id}" collection_id "${this_edit_collection_id}"
        else
          log_print error "Missing value for --collection"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

}

function item_list() {

  log_print debug "Starting Item List"

  # Check for --collection and --status flags
  this_item_collection_filter=""
  this_status_value=""

  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--help"|"-h")
        help_get_message item_list
        ;;
      "--collection")
        shift
        if [[ "${1}" ]] ; then
          this_item_collection_filter="${1}"
          log_print debug "Filter by collection: ${this_item_collection_filter}"
        else
          log_print error "Missing value for --collection"
        fi
        ;;
      "--status")
        shift
        this_status_value="${1}"
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

  this_status_filter=$(generic_build_status_filter "${this_status_value}")

  if [[ "${this_item_collection_filter}" && "${this_status_filter}" ]]; then
    generic_list collection_items_view "collection = '${this_item_collection_filter}' AND ${this_status_filter}"
  elif [[ "${this_item_collection_filter}" ]]; then
    generic_list collection_items_view "collection = '${this_item_collection_filter}'"
  elif [[ "${this_status_filter}" ]]; then
    generic_list collection_items_view "${this_status_filter}"
  else
    generic_list collection_items_view
  fi

}

function item_search() {

  log_print debug "Starting Item Search"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message item
  fi

  this_item_pattern="$1" ; log_print debug "Search pattern: ${this_item_pattern}"

  database_run box "SELECT * FROM collection_items_view WHERE name LIKE '%${this_item_pattern}%'"

}

function item_start() {

  log_print debug "Starting Item Start"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message item
  fi

  this_item_id="$1" ; log_print debug "Item ID: ${this_item_id}"

  validate_database_id collection_items "${this_item_id}"
  generic_set_status "collection_items" "${this_item_id}" "In Progress"

}

function item_stop() {

  log_print debug "Starting Item Stop"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message item
  fi

  this_item_id="$1" ; log_print debug "Item ID: ${this_item_id}"

  validate_database_id collection_items "${this_item_id}"
  generic_set_status "collection_items" "${this_item_id}" "Pending"

}

function item_complete() {

  log_print debug "Starting Item Complete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message item
  fi

  this_item_id="$1" ; log_print debug "Item ID: ${this_item_id}"

  validate_database_id collection_items "${this_item_id}"
  generic_complete "collection_items" "${this_item_id}"

}

function item_main() {

  log_print debug "Starting Item Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message item
  fi

  case "${user_arg}" in
    "add")
      item_add "$@"
      ;;
    "complete")
      item_complete "$@"
      ;;
    "delete")
      item_delete "$@"
      ;;
    "edit")
      item_edit "$@"
      ;;
    "help")
      help_get_message item
      ;;
    "list")
      item_list "$@"
      ;;
    "search")
      item_search "$@"
      ;;
    "start")
      item_start "$@"
      ;;
    "stop")
      item_stop "$@"
      ;;
    *)
      help_get_message item
      ;;
  esac

}
