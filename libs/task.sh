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

function taskEdit() {

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

function taskHelp() {
  echo "${help_banner} - Tasks"
  echo
  echo "ACTIONS:"
  echo "  add --name task_name [--project project_name] [--deadline DATE]"
  echo "  complete task_id"
  echo "  delete task_id"
  echo "  help (this message)"
  echo "  list"
  echo "  rename old_task_name new_task_name"
  echo "  start task_id"
  echo "  stop task_id"
}

function taskList() {
  database_run "SELECT * FROM task_view WHERE state <> 'Done' ORDER BY deadline ASC NULLS LAST, state DESC"
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
    "rename")
      shift
      taskRename "$@"
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
