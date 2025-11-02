#!/bin/bash

recurring_temp_file="/tmp/recurring.tmp"

function recurringAdd() {

  # Getting args
  while [[ "$@" ]] ; do
    this_arg="${1}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          this_task_name="'${1}'"
        else
          echo "Error: missing recurring task name"
          exit 1
        fi
        ;;
      "--recurrence")
        shift
        if [[ "${1}" ]] ; then
          case "${1}" in
            "daily"|"weekly"|"monthly"|"quarterly"|"biannual"|"yearly")
              this_task_recurrence="'${1}'"
              ;;
            *)
              echo "Error: wrong recurring task frequency (allowed ones are: daily, weekly, monthly, quarterly, biannual and yearly)"
              exit 1
              ;;
          esac
        else
          echo "Error: missing task recurrence"
          exit 1
        fi
        ;;
    esac

    shift
  done

  # Validating input
  if [[ ! ${this_task_name} ]]; then
    echo "Error: missing recurring task name"
    exit 1
  fi

  if [[ ! ${this_task_recurrence} ]]; then
    echo "Error: missing task recurrence"
    exit 1
  fi

  # Inserting
  database_run "INSERT INTO recurring (name, recurrence) VALUES (${this_task_name}, ${this_task_recurrence});"
  
}

function recurringComplete() {
  if [[ "$1" ]] ; then
    this_recurring_id="$1"
  else
    echo "Error: missing recurring task ID."
    exit 1
  fi

  database_run "UPDATE recurring SET state = 'Done', completion_date = DATE('now') WHERE id = $this_recurring_id;"
}

function recurringDelete() {
  this_recurring_id="$1"

  if [[ $this_recurring_id ]] ; then
    database_run "DELETE FROM recurring WHERE id = $this_recurring_id;"
  else
    echo "Error: missing recurring task ID."
    exit 1
  fi
}

function recurringHelp() {

  echo "${help_banner} - Recurring Tasks"
  echo
  echo "Actions:"
  echo "  ${help_basename} add --name TASK_NAME --recurency FREQUENCY"
  echo "  ${help_basename} complete TASK_ID"
  echo "  ${help_basename} delete TASK_ID"
  echo "  ${help_basename} help (this message)"
  echo "  ${help_basename} list"
  echo "  ${help_basename} rename OLD_TASK_NAME NEW_TASK_NAME"
  echo
  echo "Frequencies:"
  echo "  daily"
  echo "  weekly"
  echo "  monthly"
  echo "  quarterly"
  echo "  biannual"
  echo "  yearly"
  echo

}

function recurringList() {

  database_run "SELECT * FROM recurring;"

}

function recurringMain() {

  case $1 in
    "add")
      shift
      recurringAdd "$@"
      ;;
    "complete")
      shift
      recurringComplete "$1"
      ;;
    "delete")
      shift
      recurringDelete "$@"
      ;;
    "list")
      recurringList
      ;;
    "rename")
      shift
      recurringRename "$@"
      ;;
    "update")
      recurringUpdate
      ;;
    *)
      recurringHelp
      ;;
  esac

}

function recurringRename() {
  this_old_recurring_name="$1"
  this_new_recurring_name="$2"

  if [[ $this_new_recurring_name ]] ; then
    database_run "UPDATE recurring SET name='$this_new_recurring_name' WHERE name='$this_old_recurring_name';"
  else
    echo "Error: missing required args."
    exit 1
  fi
}

function recurringUpdate() {

  reference_date="2020-05-09"

  # Debugging
  echo """
    Current Day         => $(datetime_get_current_day)
    Current Week        => $(datetime_get_current_week)
    Current Month       => $(datetime_get_current_month)
    Current Quarter     => $(datetime_get_current_quarter)
    Current Semester    => $(datetime_get_current_semester)
    Current Year        => $(datetime_get_current_year)

    Reference Day       => $reference_date
    Reference Week      => $(datetime_get_week_from_date $reference_date)
    Reference Month     => $(datetime_get_month_from_date $reference_date)
    Reference Quarter   => $(datetime_get_quarter_from_date $reference_date)
    Reference Semester  => $(datetime_get_semester_from_date $reference_date)
    Reference Year      => $(datetime_get_year_from_date $reference_date)

  """
  exit 0
  # Check all recurring tasks
  # Do a loop in all completed ones
  # For each completed task, check
  # What is the recurrence?
  # Is it today still completed?

  IFS=$'\n'
  for task in $(database_silent "SELECT * FROM recurring_log;"); do
    # Mapping
    this_task_id=$(echo ${task} | cut -d, -f1)
    this_task_name=$(echo ${task} | cut -d, -f2)
    this_task_recurrence=$(echo ${task} | cut -d, -f3)
    this_task_completion=$(echo ${task} | cut -d, -f4)
    
    # Debugging
    # echo "Task ID: ${this_task_id}"
    # echo "  - Name: ${this_task_name}"
    # echo "  - Recurrence: ${this_task_recurrence}"
    # echo "  - Completion: ${this_task_completion}"

    # Comparing the dates
    echo "Recurrence: ${this_task_recurrence}"
    echo "Completion: ${this_task_completion}"

    case "${this_task_recurrence}" in
      "daily")
        ;;
      "weekly")
        ;;
      "monthly")
        ;;
      "quarterly")
        ;;
      "biannual")
        ;;
      "yearly")
        ;;
    esac

  done
  unset $IFS

  exit 0

}