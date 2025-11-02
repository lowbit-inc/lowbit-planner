#!/bin/bash

function taskAdd() {

  # Getting args
  while [[ "$@" ]] ; do
    this_arg="${1}"

    case "${this_arg}" in
      "--deadline")
        shift
        if [[ "${1}" ]] ; then
          this_task_deadline="'${1}'"
        else
          echo "Error: missing task deadline"
          exit 1
        fi
        ;;
      "--name")
        shift
        if [[ "${1}" ]] ; then
          this_task_name="'${1}'"
        else
          echo "Error: missing task name"
          exit 1
        fi
        ;;
      "--project")
        shift
        if [[ "${1}" ]] ; then
          this_task_project="${1}"
        else
          echo "Error: missing task project"
          exit 1
        fi
        ;;
    esac

    shift
  done

  # Validating input
  if [[ ! ${this_task_name} ]]; then
    echo "Error: missing task name"
    exit 1
  fi

  if [[ ${this_task_project} ]]; then
    this_project_id=$(database_silent "SELECT id FROM project WHERE name='${this_task_project}'")
    if [[ ! $this_project_id ]] ; then
      echo "Error: invalid project name."
      exit 1
    fi
  fi

  # Inserting
  database_run "INSERT INTO task (name, project_id, deadline) VALUES (${this_task_name}, ${this_project_id:-NULL}, ${this_task_deadline:-NULL});"
  
}

function taskComplete() {
  if [[ "$1" ]] ; then
    this_task_id="$1"
  else
    echo "Error: missing task ID."
    exit 1
  fi

  database_run "UPDATE task SET state = 'Done', completion_date = DATE('now') WHERE id = $this_task_id;"
}

function taskDelete() {
  this_task_id="$1"

  if [[ $this_task_id ]] ; then
    database_run "DELETE FROM task WHERE id = $this_task_id;"
  else
    echo "Error: missing task ID."
    exit 1
  fi
}

function taskHelp() {
  echo "${help_banner} - Tasks"
  echo
  echo "Actions:"
  echo "  ${help_basename} add --name TASK_NAME [--project PROJECT_NAME] [--deadline DATE]"
  echo "  ${help_basename} complete TASK_ID"
  echo "  ${help_basename} delete TASK_ID"
  echo "  ${help_basename} help (this message)"
  echo "  ${help_basename} list"
  echo "  ${help_basename} list-completed"
  echo "  ${help_basename} rename OLD_TASK_NAME NEW_TASK_NAME"
  echo "  ${help_basename} set-deadline TASK_ID [DATE]"
  echo "  ${help_basename} set-project TASK_ID [PROJECT_NAME]"
  echo "  ${help_basename} start TASK_ID"
  echo "  ${help_basename} stop TASK_ID"
  echo
}

function taskList() {
  database_run "SELECT * FROM task_view;"
}

function taskListCompleted() {
  database_run "SELECT * FROM task_log;"
}

function taskMain() {
  usr_command="$1"
  
  case "${usr_command}" in
    "add")
      shift
      taskAdd "$@"
      ;;
    "complete")
      shift
      taskComplete "$1"
      ;;
    "delete")
      shift
      taskDelete "$1"
      ;;
    "help")
      taskHelp
      ;;
    "list")
      taskList
      ;;
    "list-completed")
      taskListCompleted
      ;;
    "rename")
      shift
      taskRename "$@"
      ;;
    "set-deadline")
      shift
      taskSetDeadline "$@"
      ;;
    "set-project")
      shift
      taskSetProject "$@"
      ;;
    "start")
      shift
      taskStart "$1"
      ;;
    "stop")
      shift
      taskStop "$1"
      ;;
    *)
      taskHelp
      ;;
  esac
}

function taskRename() {
  this_old_task_name="$1"
  this_new_task_name="$2"

  if [[ $this_new_task_name ]] ; then
    database_run "UPDATE task SET name='$this_new_task_name' WHERE name='$this_old_task_name';"
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

  database_run "UPDATE task SET deadline = '$this_task_deadline' WHERE id = $this_task_id;"

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
    this_project_id=$(database_silent "SELECT id FROM project WHERE name='${this_task_project}'")
    if [[ ! $this_project_id ]] ; then
      echo "Error: invalid project name."
      exit 1
    fi
  else
    this_project_id="NULL"
  fi

  database_run "UPDATE task SET project_id = $this_project_id WHERE id = $this_task_id;"

}

function taskStart() {
  if [[ "$1" ]] ; then
    this_task_id="$1"
  else
    echo "Error: missing task ID."
    exit 1
  fi

  database_run "UPDATE task SET state = 'Started' WHERE id = $this_task_id;"
}

function taskStop() {
  if [[ "$1" ]] ; then
    this_task_id="$1"
  else
    echo "Error: missing task ID."
    exit 1
  fi

  database_run "UPDATE task SET state = 'Pending' WHERE id = $this_task_id;"
}
