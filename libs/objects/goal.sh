#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function goal_add() {

  log_print debug "Starting Goal Add"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message goal_add
  fi

  # Getting positional arg
  this_goal_name="$1" ; log_print debug "Goal name: ${this_goal_name}" ; shift

  # Getting flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--area")
        shift
        if [[ "${1}" ]] ; then
          this_goal_area_name="${1}"
          log_print debug "Area name: ${this_goal_area_name}"
        else
          log_print error "Missing value for --area"
        fi
        ;;
      "--vision")
        shift
        if [[ "${1}" ]] ; then
          this_goal_vision_name="${1}"
          log_print debug "Vision name: ${this_goal_vision_name}"
        else
          log_print error "Missing value for --vision"
        fi
        ;;
      "--start-date")
        shift
        if [[ "${1}" ]] ; then
          this_goal_start_date="${1}"
          log_print debug "Start date: ${this_goal_start_date}"
        else
          log_print error "Missing value for --start-date"
        fi
        ;;
      "--due-date")
        shift
        if [[ "${1}" ]] ; then
          this_goal_due_date="${1}"
          log_print debug "Due date: ${this_goal_due_date}"
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
  if [[ ! "${this_goal_area_name}" ]]; then
    log_print error "Missing required flag --area AREA_NAME"
  fi

  # Resolve area name to area_id
  this_goal_area_id=$(database_run csv "SELECT id FROM areas WHERE name = '${this_goal_area_name}';")
  if [[ ! "${this_goal_area_id}" ]]; then
    log_print error "Area '${this_goal_area_name}' not found"
  fi

  # Resolve vision name to vision_id (optional)
  if [[ "${this_goal_vision_name}" ]]; then
    this_goal_vision_id=$(database_run csv "SELECT id FROM visions WHERE name = '${this_goal_vision_name}';")
    if [[ ! "${this_goal_vision_id}" ]]; then
      log_print error "Vision '${this_goal_vision_name}' not found"
    fi
  fi

  if [[ "${this_goal_start_date}" ]]; then
    validate_date "${this_goal_start_date}"
  fi
  if [[ "${this_goal_due_date}" ]]; then
    validate_date "${this_goal_due_date}"
  fi

  # Build fields and values for INSERT
  this_fields="name, area_id"
  this_values="'${this_goal_name}', ${this_goal_area_id}"

  if [[ "${this_goal_start_date}" ]]; then
    this_fields="${this_fields}, start_date"
    this_values="${this_values}, '${this_goal_start_date}'"
  fi

  if [[ "${this_goal_due_date}" ]]; then
    this_fields="${this_fields}, due_date"
    this_values="${this_values}, '${this_goal_due_date}'"
  fi

  if [[ "${this_goal_vision_id}" ]]; then
    this_fields="${this_fields}, vision_id"
    this_values="${this_values}, ${this_goal_vision_id}"
  fi

  generic_add "goals" "${this_fields}" "${this_values}" "${this_goal_name}"

}

function goal_delete() {

  log_print debug "Starting Goal Delete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message goal
  fi

  # Getting positional arg
  this_goal_id="$1" ; log_print debug "Goal ID: ${this_goal_id}"

  # Validate ID
  validate_database_id goals "${this_goal_id}"

  # Fetch name for confirmation
  this_goal_name=$(database_run csv "SELECT name FROM goals WHERE id = ${this_goal_id};")

  generic_delete "goals" "id" "${this_goal_id}" "${this_goal_name}"

}

function goal_list() {

  log_print debug "Starting Goal List"

  this_status_value=""
  while [[ "$@" ]] ; do
    case "${1}" in
      "--status") shift ; this_status_value="${1}" ;;
    esac
    shift
  done

  this_status_filter=$(generic_build_status_filter "${this_status_value}")
  generic_list goals_view "${this_status_filter}"

}

function goal_edit() {

  log_print debug "Starting Goal Edit"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message goal_edit
  fi

  # Getting positional arg
  this_goal_id="$1" ; log_print debug "Goal ID: ${this_goal_id}" ; shift

  # Validate ID
  validate_database_id goals "${this_goal_id}"

  # Getting optional flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property goals id "${this_goal_id}" name "'${1}'"
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
          generic_set_property goals id "${this_goal_id}" area_id "${this_edit_area_id}"
        else
          log_print error "Missing value for --area"
        fi
        ;;
      "--vision")
        shift
        if [[ "${1}" ]] ; then
          this_edit_vision_id=$(database_run csv "SELECT id FROM visions WHERE name = '${1}';")
          if [[ ! "${this_edit_vision_id}" ]]; then
            log_print error "Vision '${1}' not found"
          fi
          generic_set_property goals id "${this_goal_id}" vision_id "${this_edit_vision_id}"
        else
          log_print error "Missing value for --vision"
        fi
        ;;
      "--start-date")
        shift
        if [[ "${1}" ]] ; then
          validate_date "${1}"
          generic_set_property goals id "${this_goal_id}" start_date "'${1}'"
        else
          log_print error "Missing value for --start-date"
        fi
        ;;
      "--due-date")
        shift
        if [[ "${1}" ]] ; then
          validate_date "${1}"
          generic_set_property goals id "${this_goal_id}" due_date "'${1}'"
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

function goal_start() {

  log_print debug "Starting Goal Start"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message goal
  fi

  this_goal_id="$1" ; log_print debug "Goal ID: ${this_goal_id}"

  validate_database_id goals "${this_goal_id}"
  generic_set_status "goals" "${this_goal_id}" "In Progress"

}

function goal_stop() {

  log_print debug "Starting Goal Stop"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message goal
  fi

  this_goal_id="$1" ; log_print debug "Goal ID: ${this_goal_id}"

  validate_database_id goals "${this_goal_id}"
  generic_set_status "goals" "${this_goal_id}" "Pending"

}

function goal_complete() {

  log_print debug "Starting Goal Complete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message goal
  fi

  this_goal_id="$1" ; log_print debug "Goal ID: ${this_goal_id}"

  validate_database_id goals "${this_goal_id}"
  generic_complete "goals" "${this_goal_id}"

}

function goal_search() {

  log_print debug "Starting Goal Search"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message goal
  fi

  this_goal_pattern="$1" ; log_print debug "Search pattern: ${this_goal_pattern}"

  database_run box "SELECT * FROM goals_view WHERE name LIKE '%${this_goal_pattern}%'"

}

function goal_main() {

  log_print debug "Starting Goal Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message goal
  fi

  case "${user_arg}" in
    "add")
      goal_add "$@"
      ;;
    "complete")
      goal_complete "$@"
      ;;
    "delete")
      goal_delete "$@"
      ;;
    "edit")
      goal_edit "$@"
      ;;
    "list")
      goal_list "$@"
      ;;
    "search")
      goal_search "$@"
      ;;
    "start")
      goal_start "$@"
      ;;
    "stop")
      goal_stop "$@"
      ;;
    "help")
      help_get_message goal
      ;;
    *)
      help_get_message goal
      ;;
  esac

}
