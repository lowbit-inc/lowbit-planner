#!/bin/bash

function goalAdd() {

  # Getting args
  while [[ "$@" ]] ; do
    this_arg="${1}"

    case "${this_arg}" in
      "--area")
        shift
        if [[ "${1}" ]] ; then
          this_goal_area="${1}"
        else
          echo "Error: missing goal area"
          exit 1
        fi
        ;;
      "--deadline")
        shift
        if [[ "${1}" ]] ; then
          this_goal_deadline="'${1}'"
        else
          echo "Error: missing goal deadline"
          exit 1
        fi
        ;;
      "--name")
        shift
        if [[ "${1}" ]] ; then
          this_goal_name="'${1}'"
        else
          echo "Error: missing goal name"
          exit 1
        fi
        ;;
    esac

    shift
  done

  # Validating input
  if [[ ! ${this_goal_name} ]]; then
    echo "Error: missing goal name"
    exit 1
  fi

  if [[ ${this_goal_area} ]]; then
    this_area_id=$(database_silent "SELECT id FROM area WHERE name='${this_goal_area}'")
    if [[ ! $this_area_id ]] ; then
      echo "Error: invalid area name."
      exit 1
    fi
  fi

  # Inserting
  database_run "INSERT INTO goal (name, area_id, deadline) VALUES (${this_goal_name}, ${this_area_id:-NULL}, ${this_goal_deadline:-NULL});"
  
}

function goalDelete() {
  this_goal_id="$1"

  if [[ $this_goal_id ]] ; then
    database_run "DELETE FROM goal WHERE id = $this_goal_id;"
  else
    echo "Error: missing goal ID."
    exit 1
  fi
}

function goalHelp() {
  echo "${help_banner} - Goals"
  echo
  echo "Actions:"
  echo "  ${help_basename} add --name GOAL_NAME [--area AREA_NAME] [--deadline DATE]"
  echo "  ${help_basename} delete GOAL_ID"
  echo "  ${help_basename} help (this message)"
  echo "  ${help_basename} list"
  echo "  ${help_basename} rename OLD_GOAL_NAME NEW_GOAL_NAME"
  echo
}

function goalList() {
  database_run "SELECT * FROM goal_view ORDER BY deadline ASC NULLS LAST"
}

function goalMain() {
  usr_command="$1"
  
  case "${usr_command}" in
    "add")
      shift
      goalAdd "$@"
      ;;
    "delete")
      shift
      goalDelete "$1"
      ;;
    "help")
      goalHelp
      ;;
    "list")
      goalList
      ;;
    "rename")
      shift
      goalRename "$@"
      ;;
    *)
      goalHelp
      ;;
  esac
}

function goalRename() {
  this_old_goal_name="$1"
  this_new_goal_name="$2"

  if [[ $this_new_goal_name ]] ; then
    database_run "UPDATE goal SET name='$this_new_goal_name' WHERE name='$this_old_goal_name';"
  else
    echo "Error: missing required args."
    exit 1
  fi
}
