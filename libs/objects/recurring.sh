#!/bin/bash

##############
# Properties #
##############

recurring_valid_recurrences="daily, weekly, monthly, quarterly, biannual, yearly"

###########
# Methods #
###########

function recurring_add() {

  log_print debug "Starting Recurring Add"

  # Scope all working vars to this call so repeated invocations (e.g. from the
  # clarify TUI) cannot leak optional flag values from a previous call.
  local this_recurring_name=""
  local this_recurring_recurrence=""
  local this_arg=""

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message recurring_add
  fi

  # Getting positional arg
  this_recurring_name="$1" ; log_print debug "Recurring name: ${this_recurring_name}" ; shift

  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--recurrence")
        shift
        if [[ "${1}" ]] ; then
          case "${1}" in
            "daily"|"weekly"|"monthly"|"quarterly"|"biannual"|"yearly")
              this_recurring_recurrence="${1}"
              log_print debug "Recurrence: ${this_recurring_recurrence}"
              ;;
            *)
              log_print error "Invalid recurrence '${1}'. Valid values: ${recurring_valid_recurrences}"
              ;;
          esac
        else
          log_print error "Missing value for --recurrence"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

  if [[ ! "${this_recurring_recurrence}" ]]; then
    log_print error "Missing required flag --recurrence (${recurring_valid_recurrences})"
  fi

  generic_add "recurrings" "name, recurrence" "'${this_recurring_name}', '${this_recurring_recurrence}'" "${this_recurring_name}"

}

function recurring_delete() {

  log_print debug "Starting Recurring Delete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message recurring
  fi

  this_recurring_id="$1" ; log_print debug "Recurring ID: ${this_recurring_id}"

  validate_database_id recurrings "${this_recurring_id}"

  this_recurring_name=$(database_run csv "SELECT name FROM recurrings WHERE id = ${this_recurring_id};")

  generic_delete "recurrings" "id" "${this_recurring_id}" "${this_recurring_name}"

}

function recurring_edit() {

  log_print debug "Starting Recurring Edit"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message recurring_edit
  fi

  this_recurring_id="$1" ; log_print debug "Recurring ID: ${this_recurring_id}" ; shift

  validate_database_id recurrings "${this_recurring_id}"

  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property recurrings id "${this_recurring_id}" name "'${1}'"
        else
          log_print error "Missing value for --name"
        fi
        ;;
      "--recurrence")
        shift
        if [[ "${1}" ]] ; then
          case "${1}" in
            "daily"|"weekly"|"monthly"|"quarterly"|"biannual"|"yearly")
              generic_set_property recurrings id "${this_recurring_id}" recurrence "'${1}'"
              ;;
            *)
              log_print error "Invalid recurrence '${1}'. Valid values: ${recurring_valid_recurrences}"
              ;;
          esac
        else
          log_print error "Missing value for --recurrence"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
        ;;
    esac

    shift
  done

}

function recurring_complete() {

  log_print debug "Starting Recurring Complete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message recurring
  fi

  this_recurring_id="$1" ; log_print debug "Recurring ID: ${this_recurring_id}"

  validate_database_id recurrings "${this_recurring_id}"

  # Fetch current status
  this_current_status=$(database_run csv "SELECT status FROM recurrings WHERE id = ${this_recurring_id};")
  this_recurring_name=$(database_run csv "SELECT name FROM recurrings WHERE id = ${this_recurring_id};")

  if [[ "${this_current_status}" == "Done" ]]; then
    log_print error "'${this_recurring_name}' is already completed for this period"
  fi

  # Set status and completed_at
  this_completed_at=$(date '+%Y-%m-%d %H:%M:%S')
  database_run box "UPDATE recurrings SET status = 'Done', completed_at = '${this_completed_at}' WHERE id = ${this_recurring_id};"
  log_print info "Completed ${color_green}${this_recurring_name}${color_reset}"

}

function recurring_search() {

  log_print debug "Starting Recurring Search"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message recurring
  fi

  this_recurring_pattern="$1" ; log_print debug "Search pattern: ${this_recurring_pattern}"

  database_run box "SELECT * FROM recurrings_view WHERE name LIKE '%${this_recurring_pattern}%'"

}

function recurring_list() {

  log_print debug "Starting Recurring List"

  # Auto-reset completed items whose period has changed
  recurring_auto_reset

  this_status_value=""
  while [[ "$@" ]] ; do
    case "${1}" in
      "--help"|"-h") help_get_message recurring_list ;;
      "--status") shift ; this_status_value="${1}" ;;
    esac
    shift
  done

  this_status_filter=$(generic_build_status_filter "${this_status_value}")
  generic_list recurrings_view "${this_status_filter}"

}

function recurring_auto_reset() {

  log_print debug "Starting Recurring Auto Reset"

  # Get all completed recurring items
  IFS=$'\n'
  for row in $(database_run csv "SELECT id, recurrence, completed_at FROM recurrings WHERE status = 'Done' AND completed_at IS NOT NULL;"); do
    this_id=$(echo "${row}" | cut -d'|' -f1)
    this_recurrence=$(echo "${row}" | cut -d'|' -f2)
    this_completed_at=$(echo "${row}" | cut -d'|' -f3)
    this_completed_date=$(echo "${this_completed_at}" | cut -d' ' -f1)

    log_print debug "Checking recurring ${this_id}: recurrence=${this_recurrence}, completed=${this_completed_date}"

    this_should_reset=false

    case "${this_recurrence}" in
      "daily")
        if [[ "$(datetime_get_current_day)" != "${this_completed_date}" ]]; then
          this_should_reset=true
        fi
        ;;
      "weekly")
        if [[ "$(datetime_get_current_week)" != "$(datetime_get_week_from_date ${this_completed_date})" ]]; then
          this_should_reset=true
        fi
        ;;
      "monthly")
        if [[ "$(datetime_get_current_month)" != "$(datetime_get_month_from_date ${this_completed_date})" ]]; then
          this_should_reset=true
        fi
        ;;
      "quarterly")
        if [[ "$(datetime_get_current_quarter)" != "$(datetime_get_quarter_from_date ${this_completed_date})" ]]; then
          this_should_reset=true
        fi
        ;;
      "biannual")
        if [[ "$(datetime_get_current_semester)" != "$(datetime_get_semester_from_date ${this_completed_date})" ]]; then
          this_should_reset=true
        fi
        ;;
      "yearly")
        if [[ "$(datetime_get_current_year)" != "$(datetime_get_year_from_date ${this_completed_date})" ]]; then
          this_should_reset=true
        fi
        ;;
    esac

    if [[ "${this_should_reset}" == "true" ]]; then
      log_print debug "Resetting recurring ${this_id} to Pending"
      database_run box "UPDATE recurrings SET status = 'Pending', completed_at = NULL WHERE id = ${this_id};"
    fi

  done
  unset IFS

}

function recurring_main() {

  log_print debug "Starting Recurring Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message recurring
  fi

  case "${user_arg}" in
    "add")
      recurring_add "$@"
      ;;
    "complete")
      recurring_complete "$@"
      ;;
    "delete")
      recurring_delete "$@"
      ;;
    "edit")
      recurring_edit "$@"
      ;;
    "help")
      help_get_message recurring
      ;;
    "list")
      recurring_list "$@"
      ;;
    "search")
      recurring_search "$@"
      ;;
    *)
      help_get_message recurring
      ;;
  esac

}
