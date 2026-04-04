#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function project_add() {

  log_print debug "Starting Project Add"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message project_add
  fi

  # Getting positional arg
  this_project_name="$1" ; log_print debug "Project name: ${this_project_name}" ; shift

  # Getting flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--area")
        shift
        if [[ "${1}" ]] ; then
          this_project_area_name="${1}"
          log_print debug "Area name: ${this_project_area_name}"
        else
          log_print error "Missing value for --area"
        fi
        ;;
      "--start-date")
        shift
        if [[ "${1}" ]] ; then
          this_project_start_date="${1}"
          log_print debug "Start date: ${this_project_start_date}"
        else
          log_print error "Missing value for --start-date"
        fi
        ;;
      "--due-date")
        shift
        if [[ "${1}" ]] ; then
          this_project_due_date="${1}"
          log_print debug "Due date: ${this_project_due_date}"
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
  if [[ ! "${this_project_area_name}" ]]; then
    log_print error "Missing required flag --area AREA_NAME"
  fi

  # Resolve area name to area_id
  this_project_area_id=$(database_run csv "SELECT id FROM areas WHERE name = '${this_project_area_name}';")
  if [[ ! "${this_project_area_id}" ]]; then
    log_print error "Area '${this_project_area_name}' not found"
  fi

  # Validate dates if provided
  if [[ "${this_project_start_date}" ]]; then
    validate_date "${this_project_start_date}"
  fi
  if [[ "${this_project_due_date}" ]]; then
    validate_date "${this_project_due_date}"
  fi

  # Build fields and values for INSERT
  this_fields="name, area_id"
  this_values="'${this_project_name}', ${this_project_area_id}"

  if [[ "${this_project_start_date}" ]]; then
    this_fields="${this_fields}, start_date"
    this_values="${this_values}, '${this_project_start_date}'"
  fi

  if [[ "${this_project_due_date}" ]]; then
    this_fields="${this_fields}, due_date"
    this_values="${this_values}, '${this_project_due_date}'"
  fi

  generic_add "projects" "${this_fields}" "${this_values}" "${this_project_name}"

}

function project_delete() {

  log_print debug "Starting Project Delete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message project
  fi

  # Getting positional arg
  this_project_id="$1" ; log_print debug "Project ID: ${this_project_id}"

  # Validate ID
  validate_database_id projects "${this_project_id}"

  # Fetch name for confirmation
  this_project_name=$(database_run csv "SELECT name FROM projects WHERE id = ${this_project_id};")

  # Confirmation
  log_print user "Are you sure you want to delete project ${this_project_id} (${this_project_name})?"

  # Execution
  database_run box "DELETE FROM projects WHERE id = ${this_project_id};" ; database_run_rc=$?

  if [[ $database_run_rc -eq 0 ]]; then
    log_print info "Item ${this_project_id} deleted from projects"
  else
    log_print error "Failed to delete item from projects"
  fi

}

function project_list() {

  log_print debug "Starting Project List"

  generic_list projects_view

}

function project_edit() {

  log_print debug "Starting Project Edit"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message project
  fi

  # Getting positional arg
  this_project_id="$1" ; log_print debug "Project ID: ${this_project_id}" ; shift

  # Validate ID
  validate_database_id projects "${this_project_id}"

  # Getting optional flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property projects id "${this_project_id}" name "'${1}'"
        else
          log_print error "Missing value for --name"
        fi
        ;;
      "--goal")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property projects id "${this_project_id}" goal_id "${1}"
        else
          log_print error "Missing value for --goal"
        fi
        ;;
      "--area")
        shift
        if [[ "${1}" ]] ; then
          this_edit_area_id=$(database_run csv "SELECT id FROM areas WHERE name = '${1}';")
          if [[ ! "${this_edit_area_id}" ]]; then
            log_print error "Area '${1}' not found"
          fi
          generic_set_property projects id "${this_project_id}" area_id "${this_edit_area_id}"
        else
          log_print error "Missing value for --area"
        fi
        ;;
      "--start-date")
        shift
        if [[ "${1}" ]] ; then
          validate_date "${1}"
          generic_set_property projects id "${this_project_id}" start_date "'${1}'"
        else
          log_print error "Missing value for --start-date"
        fi
        ;;
      "--due-date")
        shift
        if [[ "${1}" ]] ; then
          validate_date "${1}"
          generic_set_property projects id "${this_project_id}" due_date "'${1}'"
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

function project_start() {

  log_print debug "Starting Project Start"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message project
  fi

  this_project_id="$1" ; log_print debug "Project ID: ${this_project_id}"

  validate_database_id projects "${this_project_id}"

  generic_set_property projects id "${this_project_id}" status "'In Progress'"

}

function project_stop() {

  log_print debug "Starting Project Stop"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message project
  fi

  this_project_id="$1" ; log_print debug "Project ID: ${this_project_id}"

  validate_database_id projects "${this_project_id}"

  generic_set_property projects id "${this_project_id}" status "'Pending'"

}

function project_complete() {

  log_print debug "Starting Project Complete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message project
  fi

  this_project_id="$1" ; log_print debug "Project ID: ${this_project_id}"

  validate_database_id projects "${this_project_id}"

  generic_set_property projects id "${this_project_id}" status "'Done'"
  generic_set_property projects id "${this_project_id}" completed_at "DATE('now', 'localtime')"

}

function project_search() {

  log_print debug "Starting Project Search"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message project
  fi

  this_project_pattern="$1" ; log_print debug "Search pattern: ${this_project_pattern}"

  database_run box "SELECT * FROM projects_view WHERE name LIKE '%${this_project_pattern}%'"

}

function project_main() {

  log_print debug "Starting Project Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message project
  fi

  case "${user_arg}" in
    "add")
      project_add "$@"
      ;;
    "complete")
      project_complete "$@"
      ;;
    "delete")
      project_delete "$@"
      ;;
    "edit")
      project_edit "$@"
      ;;
    "list")
      project_list
      ;;
    "search")
      project_search "$@"
      ;;
    "start")
      project_start "$@"
      ;;
    "stop")
      project_stop "$@"
      ;;
    "help")
      help_get_message project
      ;;
    *)
      help_get_message project
      ;;
  esac

}
