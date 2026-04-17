#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function vision_add() {

  log_print debug "Starting Vision Add"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message vision_add
  fi

  # Getting positional arg
  this_vision_name="$1" ; log_print debug "Vision name: ${this_vision_name}" ; shift

  # Getting flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--area")
        shift
        if [[ "${1}" ]] ; then
          this_vision_area_name="${1}"
          log_print debug "Area name: ${this_vision_area_name}"
        else
          log_print error "Missing value for --area"
        fi
        ;;
      "--description")
        shift
        if [[ "${1}" ]] ; then
          this_vision_description="${1}"
          log_print debug "Description: ${this_vision_description}"
        else
          log_print error "Missing value for --description"
        fi
        ;;
      "--start-date")
        shift
        if [[ "${1}" ]] ; then
          this_vision_start_date="${1}"
          log_print debug "Start date: ${this_vision_start_date}"
        else
          log_print error "Missing value for --start-date"
        fi
        ;;
      "--due-date")
        shift
        if [[ "${1}" ]] ; then
          this_vision_due_date="${1}"
          log_print debug "Due date: ${this_vision_due_date}"
        else
          log_print error "Missing value for --due-date"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

  # Validate --area is provided (required)
  if [[ ! "${this_vision_area_name}" ]]; then
    help_get_message vision_add
  fi

  # Resolve area name to area_id
  this_vision_area_id=$(database_run csv "SELECT id FROM areas WHERE name = '${this_vision_area_name}';")
  if [[ ! "${this_vision_area_id}" ]]; then
    log_print error "Area '${this_vision_area_name}' not found"
  fi

  if [[ "${this_vision_start_date}" ]]; then
    validate_date "${this_vision_start_date}"
  fi
  if [[ "${this_vision_due_date}" ]]; then
    validate_date "${this_vision_due_date}"
  fi

  # Build fields and values for INSERT
  this_fields="name, area_id"
  this_values="'${this_vision_name}', ${this_vision_area_id}"

  if [[ "${this_vision_description}" ]]; then
    this_fields="${this_fields}, description"
    this_values="${this_values}, '${this_vision_description}'"
  fi

  if [[ "${this_vision_start_date}" ]]; then
    this_fields="${this_fields}, start_date"
    this_values="${this_values}, '${this_vision_start_date}'"
  fi

  if [[ "${this_vision_due_date}" ]]; then
    this_fields="${this_fields}, due_date"
    this_values="${this_values}, '${this_vision_due_date}'"
  fi

  generic_add "visions" "${this_fields}" "${this_values}" "${this_vision_name}"

}


function vision_delete() {

  log_print debug "Starting Vision Delete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message vision
  fi

  # Getting positional arg
  this_vision_id="$1" ; log_print debug "Vision ID: ${this_vision_id}"

  # Validate ID
  validate_database_id visions "${this_vision_id}"

  # Fetch name for confirmation
  this_vision_name=$(database_run csv "SELECT name FROM visions WHERE id = ${this_vision_id};")

  generic_delete "visions" "id" "${this_vision_id}" "${this_vision_name}"

}

function vision_list() {

  log_print debug "Starting Vision List"

  this_status_value=""
  while [[ "$@" ]] ; do
    case "${1}" in
      "--help"|"-h") help_get_message vision_list ;;
      "--status") shift ; this_status_value="${1}" ;;
    esac
    shift
  done

  this_status_filter=$(generic_build_status_filter "${this_status_value}")
  generic_list visions_view "${this_status_filter}"

}

function vision_edit() {

  log_print debug "Starting Vision Edit"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message vision_edit
  fi

  # Getting positional arg
  this_vision_id="$1" ; log_print debug "Vision ID: ${this_vision_id}" ; shift

  # Validate ID
  validate_database_id visions "${this_vision_id}"

  # Getting optional flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property visions id "${this_vision_id}" name "'${1}'"
        else
          log_print error "Missing value for --name"
        fi
        ;;
      "--area")
        shift
        if [[ "${1}" ]] ; then
          this_edit_area_id=$(database_run csv "SELECT id FROM areas WHERE name = '${1}';")
          if [[ ! "${this_edit_area_id}" ]]; then
            log_print error "Area '${1}' not found"
          fi
          generic_set_property visions id "${this_vision_id}" area_id "${this_edit_area_id}"
        else
          log_print error "Missing value for --area"
        fi
        ;;
      "--description")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property visions id "${this_vision_id}" description "'${1}'"
        else
          log_print error "Missing value for --description"
        fi
        ;;
      "--start-date")
        shift
        if [[ "${1}" ]] ; then
          validate_date "${1}"
          generic_set_property visions id "${this_vision_id}" start_date "'${1}'"
        else
          log_print error "Missing value for --start-date"
        fi
        ;;
      "--due-date")
        shift
        if [[ "${1}" ]] ; then
          validate_date "${1}"
          generic_set_property visions id "${this_vision_id}" due_date "'${1}'"
        else
          log_print error "Missing value for --due-date"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

}

function vision_start() {

  log_print debug "Starting Vision Start"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message vision
  fi

  this_vision_id="$1" ; log_print debug "Vision ID: ${this_vision_id}"

  validate_database_id visions "${this_vision_id}"
  generic_set_status "visions" "${this_vision_id}" "In Progress"

}

function vision_stop() {

  log_print debug "Starting Vision Stop"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message vision
  fi

  this_vision_id="$1" ; log_print debug "Vision ID: ${this_vision_id}"

  validate_database_id visions "${this_vision_id}"
  generic_set_status "visions" "${this_vision_id}" "Pending"

}

function vision_complete() {

  log_print debug "Starting Vision Complete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message vision
  fi

  this_vision_id="$1" ; log_print debug "Vision ID: ${this_vision_id}"

  validate_database_id visions "${this_vision_id}"
  generic_complete "visions" "${this_vision_id}"

}

function vision_search() {

  log_print debug "Starting Vision Search"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message vision
  fi

  this_vision_pattern="$1" ; log_print debug "Search pattern: ${this_vision_pattern}"

  database_run box "SELECT * FROM visions_view WHERE name LIKE '%${this_vision_pattern}%'"

}

function vision_main() {

  log_print debug "Starting Vision Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message vision
  fi

  case "${user_arg}" in
    "add")
      vision_add "$@"
      ;;
    "complete")
      vision_complete "$@"
      ;;
    "delete")
      vision_delete "$@"
      ;;
    "edit")
      vision_edit "$@"
      ;;
    "list")
      vision_list "$@"
      ;;
    "search")
      vision_search "$@"
      ;;
    "start")
      vision_start "$@"
      ;;
    "stop")
      vision_stop "$@"
      ;;
    "help")
      help_get_message vision
      ;;
    *)
      help_get_message vision
      ;;
  esac

}
