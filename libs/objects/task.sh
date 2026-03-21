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

  if [[ "${1}" ]]; then
    user_args="$@"
    log_print debug "User args: ${user_args}"
  else
    log_print debug "No user arg provided - calling help message"
    task_add_help
  fi

  echo "Oi!"
  exit 0

  # Mapping args
  # this_inbox_item="${user_args}"
  
  # database_run box "INSERT INTO inbox (name) VALUES ('$this_inbox_item');" ; database_run_rc=$?

  # if [[ $database_run_rc -eq 0 ]] ; then
  #   log_print info "Item added to inbox (${this_inbox_item})"
  # else
  #   log_print error "Failed to add item to inbox"
  # fi

}

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
    this_project_id=$(database_run "csv" "SELECT id FROM project WHERE name='${this_task_project}'")
    if [[ ! $this_project_id ]] ; then
      echo "Error: invalid project name."
      exit 1
    fi
  fi

  # Inserting
  database_run "box" "INSERT INTO task (name, project_id, deadline) VALUES (${this_task_name}, ${this_project_id:-NULL}, ${this_task_deadline:-NULL});"
  
}

function task_help() {
  log_print debug "Getting help message: task"
  printf "${color_bold}${system_long_name} - Task${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Manage tasks (next actions).\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} task ${color_green}SUBCOMMAND ${color_blue}[ARGS]${color_reset}\n"
  printf "\n"
  printf "${color_bold}SUBCOMMANDS:${color_reset}\n"
  printf "  add ${color_blue}TASK_NAME [ARGS]${color_reset}\n"
  printf "  complete ${color_blue}TASK_ID${color_reset}\n"
  printf "  delete ${color_blue}TASK_ID${color_reset}\n"
  printf "  edit ${color_blue}TASK_ID${color_reset}\n"
  printf "  list ${color_blue}[--completed|--all]${color_reset}\n"
  printf "  search ${color_blue}PATTERN${color_reset}\n"
  printf "  start ${color_blue}TASK_ID${color_reset}\n"
  printf "  stop ${color_blue}TASK_ID${color_reset}\n"
  printf "\n"
  exit 0
}

function task_main() {

  log_print debug "Starting Task Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    task_help
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
      task_help
      ;;
    "list")
      task_list
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
      task_help
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
