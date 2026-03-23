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
    user_args="$@"
    log_print debug "User args: ${user_args}"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message task_add
  fi

  # Getting positional args
  this_task_name="$1" ; log_print debug "Task name: ${this_task_name}" ; shift

  # Getting all other args
  while [[ "$@" ]] ; do
    this_arg="${1}"
    log_print debug "Got arg: ${this_arg}"

    case "${this_arg}" in
      "--due-date")
        shift
        if [[ "${1}" ]] ; then
          this_task_due_date="${1}" && validate_date "${this_task_due_date}"
          log_print debug "Task Due Date: ${this_task_due_date}"
        else
          log_print error "Missing value for due date"
        fi
        ;;
      # "--project")
      #   shift
      #   if [[ "${1}" ]] ; then
      #     this_task_project="${1}" && validate_database_record "project" "name" "${this_task_project}"
      #     log_print debug "Task Project: ${this_task_project}"
      #   else
      #     log_print error "Missing value for project"
      #   fi
      #   ;;
      "--start-date")
        shift
        if [[ "${1}" ]] ; then
          this_task_start_date="${1}" && validate_date "${this_task_start_date}"
          log_print debug "Task Start Date: ${this_task_start_date}"
        else
          log_print error "Missing value for start date"
        fi
        ;;
      *)
        log_print debug "Unknown arg - ignoring"
    esac

    # Next arg
    shift
  
  done

  # Validating required args
  ## Only the positional...

  # Adding object
  generic_add "tasks" "name" "'${this_task_name}'" "${this_task_name}"

  # Settings properties
  ## Due Date
  if [[ $this_task_due_date ]]; then
    generic_set_property "tasks" "name" "'${this_task_name}'" "due_date" "'${this_task_due_date}'"
  fi
  ## Project
  # Soon...
  ## Start Date
  if [[ $this_task_start_date ]]; then
    generic_set_property "tasks" "name" "'${this_task_name}'" "start_date" "'${this_task_start_date}'"
  fi

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
      task_complete "$1"
      ;;
    "delete")
      task_delete "$1"
      ;;
    "edit")
      task_edit "$1"
      ;;
    "help")
      help_get_message task
      ;;
    "list")
      generic_list tasks_view
      ;;
    "search")
      task_search "$1"
      ;;
    "start")
      task_start "$1"
      ;;
    "stop")
      task_stop "$1"
      ;;
    *)
      help_get_message task
      ;;
  esac
}

#######
# Old #
#######

function taskComplete() {
  if [[ "$1" ]] ; then
    this_task_id="$1"
  else
    echo "Error: missing task ID."
    exit 1
  fi

  database_run "box" "UPDATE task SET state = 'Done', completion_date = DATE('now', 'localtime') WHERE id = $this_task_id;"
}

function taskDelete() {
  this_task_id="$1"

  if [[ $this_task_id ]] ; then
    database_run "box" "DELETE FROM task WHERE id = $this_task_id;"
  else
    echo "Error: missing task ID."
    exit 1
  fi
}


function taskList() {
  database_run "box" "SELECT * FROM task_view;"
}

function taskListCompleted() {
  database_run "box" "SELECT * FROM task_log;"
}


function taskRename() {
  this_old_task_name="$1"
  this_new_task_name="$2"

  if [[ $this_new_task_name ]] ; then
    database_run "box" "UPDATE task SET name='$this_new_task_name' WHERE name='$this_old_task_name';"
  else
    echo "Error: missing required args."
    exit 1
  fi
}

function taskSetDeadline() {
  if [[ ! $1 ]]; then
    echo "Error: missing required args."
    exit 1
  fi

  this_task_id="$1"
  this_task_deadline="$2"

  database_run "box" "UPDATE task SET deadline = '$this_task_deadline' WHERE id = $this_task_id;"

}

function taskSetProject() {
  if [[ ! $1 ]]; then
    echo "Error: missing required args."
    exit 1
  fi

  this_task_id="$1"
  this_task_project="$2"

  # Validating project
  if [[ ${this_task_project} ]]; then
    this_project_id=$(database_run "csv" "SELECT id FROM project WHERE name='${this_task_project}'")
    if [[ ! $this_project_id ]] ; then
      echo "Error: invalid project name."
      exit 1
    fi
  else
    this_project_id="NULL"
  fi

  database_run "box" "UPDATE task SET project_id = $this_project_id WHERE id = $this_task_id;"

}

function taskStart() {
  if [[ "$1" ]] ; then
    this_task_id="$1"
  else
    echo "Error: missing task ID."
    exit 1
  fi

  database_run "box" "UPDATE task SET state = 'Started' WHERE id = $this_task_id;"
}

function taskStop() {
  if [[ "$1" ]] ; then
    this_task_id="$1"
  else
    echo "Error: missing task ID."
    exit 1
  fi

  database_run "box" "UPDATE task SET state = 'Pending' WHERE id = $this_task_id;"
}
