#!/bin/bash

##############
# Properties #
##############

habit_valid_recurrences="daily, weekly, monthly, quarterly, biannual, yearly"

###########
# Methods #
###########

function habit_add() {

  log_print debug "Starting Habit Add"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message habit_add
  fi

  # Getting positional arg
  this_habit_name="$1" ; log_print debug "Habit name: ${this_habit_name}" ; shift

  # Getting required flag
  this_habit_recurrence=""

  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--recurrence")
        shift
        if [[ "${1}" ]] ; then
          case "${1}" in
            "daily"|"weekly"|"monthly"|"quarterly"|"biannual"|"yearly")
              this_habit_recurrence="${1}"
              log_print debug "Recurrence: ${this_habit_recurrence}"
              ;;
            *)
              log_print error "Invalid recurrence '${1}'. Valid values: ${habit_valid_recurrences}"
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

  if [[ ! "${this_habit_recurrence}" ]]; then
    log_print error "Missing required flag --recurrence (${habit_valid_recurrences})"
  fi

  generic_add "habits" "name, recurrence" "'${this_habit_name}', '${this_habit_recurrence}'" "${this_habit_name}"

}

function habit_delete() {

  log_print debug "Starting Habit Delete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message habit
  fi

  this_habit_id="$1" ; log_print debug "Habit ID: ${this_habit_id}"

  validate_database_id habits "${this_habit_id}"

  this_habit_name=$(database_run csv "SELECT name FROM habits WHERE id = ${this_habit_id};")

  generic_delete "habits" "id" "${this_habit_id}" "${this_habit_name}"

}

function habit_edit() {

  log_print debug "Starting Habit Edit"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message habit_edit
  fi

  this_habit_id="$1" ; log_print debug "Habit ID: ${this_habit_id}" ; shift

  validate_database_id habits "${this_habit_id}"

  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          generic_set_property habits id "${this_habit_id}" name "'${1}'"
        else
          log_print error "Missing value for --name"
        fi
        ;;
      "--recurrence")
        shift
        if [[ "${1}" ]] ; then
          case "${1}" in
            "daily"|"weekly"|"monthly"|"quarterly"|"biannual"|"yearly")
              generic_set_property habits id "${this_habit_id}" recurrence "'${1}'"
              ;;
            *)
              log_print error "Invalid recurrence '${1}'. Valid values: ${habit_valid_recurrences}"
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

function habit_complete() {

  log_print debug "Starting Habit Complete"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message habit
  fi

  this_habit_id="$1" ; log_print debug "Habit ID: ${this_habit_id}"

  validate_database_id habits "${this_habit_id}"

  this_current_status=$(database_run csv "SELECT status FROM habits WHERE id = ${this_habit_id};")
  this_habit_name=$(database_run csv "SELECT name FROM habits WHERE id = ${this_habit_id};")

  if [[ "${this_current_status}" == "Done" ]]; then
    log_print error "'${this_habit_name}' is already completed for this period"
  fi

  this_completed_at=$(date '+%Y-%m-%d %H:%M:%S')
  database_run box "UPDATE habits SET status = 'Done', completed_at = '${this_completed_at}' WHERE id = ${this_habit_id};"
  log_print info "Completed ${color_green}${this_habit_name}${color_reset}"

}

function habit_search() {

  log_print debug "Starting Habit Search"

  if [[ "${1}" ]]; then
    log_print debug "User args: $@"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message habit
  fi

  this_habit_pattern="$1" ; log_print debug "Search pattern: ${this_habit_pattern}"

  database_run box "SELECT * FROM habits_view WHERE name LIKE '%${this_habit_pattern}%'"

}

function habit_list() {

  log_print debug "Starting Habit List"

  # Auto-reset completed items whose period has changed
  habit_auto_reset

  this_status_value=""
  while [[ "$@" ]] ; do
    case "${1}" in
      "--help"|"-h") help_get_message habit_list ;;
      "--status") shift ; this_status_value="${1}" ;;
    esac
    shift
  done

  this_status_filter=$(generic_build_status_filter "${this_status_value}")
  generic_list habits_view "${this_status_filter}"

}

function habit_auto_reset() {

  log_print debug "Starting Habit Auto Reset"

  IFS=$'\n'
  for row in $(database_run csv "SELECT id, recurrence, completed_at FROM habits WHERE status = 'Done' AND completed_at IS NOT NULL;"); do
    this_id=$(echo "${row}" | cut -d'|' -f1)
    this_recurrence=$(echo "${row}" | cut -d'|' -f2)
    this_completed_at=$(echo "${row}" | cut -d'|' -f3)
    this_completed_date=$(echo "${this_completed_at}" | cut -d' ' -f1)

    log_print debug "Checking habit ${this_id}: recurrence=${this_recurrence}, completed=${this_completed_date}"

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
      log_print debug "Resetting habit ${this_id} to Pending"
      database_run box "UPDATE habits SET status = 'Pending', completed_at = NULL WHERE id = ${this_id};"
    fi

  done
  unset IFS

}

function habit_main() {

  log_print debug "Starting Habit Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message habit
  fi

  case "${user_arg}" in
    "add")
      habit_add "$@"
      ;;
    "complete")
      habit_complete "$@"
      ;;
    "delete")
      habit_delete "$@"
      ;;
    "edit")
      habit_edit "$@"
      ;;
    "help")
      help_get_message habit
      ;;
    "list")
      habit_list "$@"
      ;;
    "search")
      habit_search "$@"
      ;;
    *)
      help_get_message habit
      ;;
  esac

}
