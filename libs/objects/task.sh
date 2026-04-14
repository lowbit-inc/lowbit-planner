#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function task_add() {

  log_print debug "Starting Task Add"

  # Reading args
  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message task_add
  fi

  # Getting positional arg
  this_task_name="$1" ; log_print debug "Task name: ${this_task_name}" ; shift

  # Getting all other args
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--project")
        shift
        if [[ "${1}" ]] ; then
          this_task_project_name="${1}"
          log_print debug "Task Project Name: ${this_task_project_name}"
        else
          log_print error "Missing value for --project"
        fi
        ;;
      "--due-date")
        shift
        if [[ "${1}" ]] ; then
          this_task_due_date="${1}"
          log_print debug "Task Due Date: ${this_task_due_date}"
        else
          log_print error "Missing value for --due-date"
        fi
        ;;
      "--start-date")
        shift
        if [[ "${1}" ]] ; then
          this_task_start_date="${1}"
          log_print debug "Task Start Date: ${this_task_start_date}"
        else
          log_print error "Missing value for --start-date"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

  # Resolve project name to project_id if provided
  if [[ "${this_task_project_name}" ]]; then
    this_task_project_id=$(database_run csv "SELECT id FROM projects WHERE name = '${this_task_project_name}';")
    if [[ ! "${this_task_project_id}" ]]; then
      log_print error "Project '${this_task_project_name}' not found"
    fi
  fi

  # Validate dates if provided
  if [[ "${this_task_start_date}" ]]; then
    validate_date "${this_task_start_date}"
  fi
  if [[ "${this_task_due_date}" ]]; then
    validate_date "${this_task_due_date}"
  fi

  # Build fields and values for single INSERT
  this_fields="name"
  this_values="'${this_task_name}'"

  if [[ "${this_task_project_id}" ]]; then
    this_fields="${this_fields}, project_id"
    this_values="${this_values}, ${this_task_project_id}"
  fi

  if [[ "${this_task_start_date}" ]]; then
    this_fields="${this_fields}, start_date"
    this_values="${this_values}, '${this_task_start_date}'"
  fi

  if [[ "${this_task_due_date}" ]]; then
    this_fields="${this_fields}, due_date"
    this_values="${this_values}, '${this_task_due_date}'"
  fi

  generic_add "tasks" "${this_fields}" "${this_values}" "${this_task_name}"

}

function task_delete() {

  log_print debug "Starting Task Delete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message task
  fi

  # Getting positional arg
  this_task_id="$1" ; log_print debug "Task ID: ${this_task_id}"

  # Validate ID
  validate_database_id tasks "${this_task_id}"

  # Fetch name for confirmation
  this_task_name=$(database_run csv "SELECT name FROM tasks WHERE id = ${this_task_id};")

  generic_delete "tasks" "id" "${this_task_id}" "${this_task_name}"

}

function task_edit() {

  log_print debug "Starting Task Edit"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message task_edit
  fi

  # Getting positional arg
  this_task_id="$1" ; log_print debug "Task ID: ${this_task_id}" ; shift

  # Validate ID
  validate_database_id tasks "${this_task_id}"

  # Getting optional flags
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property tasks id "${this_task_id}" name "'${1}'"
        else
          log_print error "Missing value for --name"
        fi
        ;;
      "--project")
        shift
        if [[ "${1}" ]] ; then
          this_edit_project_id=$(database_run csv "SELECT id FROM projects WHERE name = '${1}';")
          if [[ ! "${this_edit_project_id}" ]]; then
            log_print error "Project '${1}' not found"
          fi
          generic_set_property tasks id "${this_task_id}" project_id "${this_edit_project_id}"
        else
          log_print error "Missing value for --project"
        fi
        ;;
      "--start-date")
        shift
        if [[ "${1}" ]] ; then
          validate_date "${1}"
          generic_set_property tasks id "${this_task_id}" start_date "'${1}'"
        else
          log_print error "Missing value for --start-date"
        fi
        ;;
      "--due-date")
        shift
        if [[ "${1}" ]] ; then
          validate_date "${1}"
          generic_set_property tasks id "${this_task_id}" due_date "'${1}'"
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

function task_start() {

  log_print debug "Starting Task Start"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message task
  fi

  this_task_id="$1" ; log_print debug "Task ID: ${this_task_id}"

  validate_database_id tasks "${this_task_id}"
  generic_set_status "tasks" "${this_task_id}" "In Progress"

}

function task_stop() {

  log_print debug "Starting Task Stop"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message task
  fi

  this_task_id="$1" ; log_print debug "Task ID: ${this_task_id}"

  validate_database_id tasks "${this_task_id}"
  generic_set_status "tasks" "${this_task_id}" "Pending"

}

function task_complete() {

  log_print debug "Starting Task Complete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message task
  fi

  this_task_id="$1" ; log_print debug "Task ID: ${this_task_id}"

  validate_database_id tasks "${this_task_id}"
  generic_complete "tasks" "${this_task_id}"

}

function task_search() {

  log_print debug "Starting Task Search"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message task
  fi

  this_task_pattern="$1" ; log_print debug "Search pattern: ${this_task_pattern}"

  database_run box "SELECT * FROM tasks_view WHERE name LIKE '%${this_task_pattern}%'"

}

function task_list() {

  log_print debug "Starting Task List"

  # Parse --status flag
  this_status_value=""
  while [[ "$@" ]] ; do
    case "${1}" in
      "--status")
        shift
        this_status_value="${1}"
        ;;
    esac
    shift
  done

  this_status_filter=$(generic_build_status_filter "${this_status_value}")
  generic_list tasks_view "${this_status_filter}"

}

function task_main() {

  log_print debug "Starting Task Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message task
  fi

  case "${user_arg}" in
    "add")
      task_add "$@"
      ;;
    "complete")
      task_complete "$@"
      ;;
    "delete")
      task_delete "$@"
      ;;
    "edit")
      task_edit "$@"
      ;;
    "help")
      help_get_message task
      ;;
    "list")
      task_list "$@"
      ;;
    "search")
      task_search "$@"
      ;;
    "start")
      task_start "$@"
      ;;
    "stop")
      task_stop "$@"
      ;;
    *)
      help_get_message task
      ;;
  esac
}
