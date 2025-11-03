#!/bin/bash

function habitAdd() {

  # Getting args
  while [[ "$@" ]] ; do
    this_arg="${1}"

    case "${this_arg}" in
      "--name")
        shift
        if [[ "${1}" ]] ; then
          this_habit_name="'${1}'"
        else
          echo "Error: missing habit name"
          exit 1
        fi
        ;;
      "--recurrence")
        shift
        if [[ "${1}" ]] ; then
          case "${1}" in
            "daily"|"weekly"|"monthly"|"quarterly"|"biannual"|"yearly")
              this_habit_recurrence="'${1}'"
              ;;
            *)
              echo "Error: wrong habit frequency (allowed ones are: daily, weekly, monthly, quarterly, biannual and yearly)"
              exit 1
              ;;
          esac
        else
          echo "Error: missing habit recurrence"
          exit 1
        fi
        ;;
    esac

    shift
  done

  # Validating input
  if [[ ! ${this_habit_name} ]]; then
    echo "Error: missing habit name"
    exit 1
  fi

  if [[ ! ${this_habit_recurrence} ]]; then
    echo "Error: missing habit recurrence"
    exit 1
  fi

  # Inserting
  database_run "INSERT INTO habit (name, recurrence) VALUES (${this_habit_name}, ${this_habit_recurrence});"
  
}

function habitComplete() {
  if [[ "$1" ]] ; then
    this_habit_id="$1"
  else
    echo "Error: missing habit ID."
    exit 1
  fi

  database_run "UPDATE habit SET state = 'Done', completion_date = DATE('now', 'localtime') WHERE id = $this_habit_id;"
}

function habitDelete() {
  this_habit_id="$1"

  if [[ $this_habit_id ]] ; then
    database_run "DELETE FROM habit WHERE id = $this_habit_id;"
  else
    echo "Error: missing habit ID."
    exit 1
  fi
}

function habitHelp() {

  echo "${help_banner} - Habits"
  echo
  echo "Actions:"
  echo "  ${help_basename} add --name HABIT_NAME --recurrence FREQUENCY"
  echo "  ${help_basename} complete HABIT_ID"
  echo "  ${help_basename} delete HABIT_ID"
  echo "  ${help_basename} help (this message)"
  echo "  ${help_basename} list"
  echo "  ${help_basename} rename OLD_HABIT_NAME NEW_HABIT_NAME"
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

function habitList() {

  # Updating before listing
  habitUpdate

  # Listing
  database_run "SELECT * FROM habit;"

}

function habitMain() {

  case $1 in
    "add")
      shift
      habitAdd "$@"
      ;;
    "complete")
      shift
      habitComplete "$1"
      ;;
    "delete")
      shift
      habitDelete "$@"
      ;;
    "list")
      habitList
      ;;
    "rename")
      shift
      habitRename "$@"
      ;;
    # "update")
    #   habitUpdate
    #   ;;
    *)
      habitHelp
      ;;
  esac

}

function habitRename() {
  this_old_habit_name="$1"
  this_new_habit_name="$2"

  if [[ $this_new_habit_name ]] ; then
    database_run "UPDATE habit SET name='$this_new_habit_name' WHERE name='$this_old_habit_name';"
  else
    echo "Error: missing required args."
    exit 1
  fi
}

function habitUncheck() {
  if [[ "$1" ]] ; then
    this_habit_id="$1"
  else
    echo "Error: missing habit ID."
    exit 1
  fi

  database_run "UPDATE habit SET state = 'Pending', completion_date = NULL WHERE id = $this_habit_id;"
}

function habitUpdate() {

  IFS=$'\n'
  for habit in $(database_silent "SELECT * FROM habit_log;"); do
    # Mapping
    this_habit_id=$(echo ${habit} | cut -d, -f1)
    this_habit_name=$(echo ${habit} | cut -d, -f2)
    this_habit_recurrence=$(echo ${habit} | cut -d, -f3)
    this_habit_completion=$(echo ${habit} | cut -d, -f4)
    
    # Debugging
    # echo "Habit ID: ${this_habit_id}"
    # echo "  - Name: ${this_habit_name}"
    # echo "  - Recurrence: ${this_habit_recurrence}"
    # echo "  - Completion: ${this_habit_completion}"

    case "${this_habit_recurrence}" in
      "daily")
        if [[ $(datetime_get_current_day) != "$this_habit_completion" ]] ; then
          habitUncheck ${this_habit_id}
          # echo "$(datetime_get_current_day) != $this_habit_completion"
        fi
        ;;
      "weekly")
        if [[ $(datetime_get_current_week) != $(datetime_get_week_from_date $this_habit_completion) ]] ; then
          habitUncheck ${this_habit_id}
          # echo "$(datetime_get_current_week) != $(datetime_get_week_from_date $this_habit_completion)"
        fi
        ;;
      "monthly")
        if [[ $(datetime_get_current_month) != $(datetime_get_month_from_date $this_habit_completion) ]] ; then
          habitUncheck ${this_habit_id}
          # echo "$(datetime_get_current_month) != $(datetime_get_month_from_date $this_habit_completion)"
        fi
        ;;
      "quarterly")
        if [[ $(datetime_get_current_quarter) != $(datetime_get_quarter_from_date $this_habit_completion) ]] ; then
          habitUncheck ${this_habit_id}
          # echo "$(datetime_get_current_quarter) != $(datetime_get_quarter_from_date $this_habit_completion)"
        fi
        ;;
      "biannual")
        if [[ $(datetime_get_current_semester) != $(datetime_get_semester_from_date $this_habit_completion) ]] ; then
          habitUncheck ${this_habit_id}
          # echo "$(datetime_get_current_semester) != $(datetime_get_semester_from_date $this_habit_completion)"
        fi
        ;;
      "yearly")
        if [[ $(datetime_get_current_year) != $(datetime_get_year_from_date $this_habit_completion) ]] ; then
          habitUncheck ${this_habit_id}
          # echo "$(datetime_get_current_year) != $(datetime_get_year_from_date $this_habit_completion)"
        fi
        ;;
    esac

  done
  unset $IFS

}
