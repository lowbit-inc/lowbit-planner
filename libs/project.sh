#!/bin/bash

function projectAdd() {

  # Getting args
  while [[ "$@" ]] ; do
    this_arg="${1}"

    case "${this_arg}" in
      "--area")
        shift
        if [[ "${1}" ]] ; then
          this_project_area="${1}"
        else
          echo "Error: missing project area"
          exit 1
        fi
        ;;
      "--deadline")
        shift
        if [[ "${1}" ]] ; then
          this_project_deadline="'${1}'"
        else
          echo "Error: missing project deadline"
          exit 1
        fi
        ;;
      "--name")
        shift
        if [[ "${1}" ]] ; then
          this_project_name="'${1}'"
        else
          echo "Error: missing project name"
          exit 1
        fi
        ;;
    esac

    shift
  done

  # Validating input
  if [[ ! ${this_project_name} ]]; then
    echo "Error: missing project name"
    exit 1
  fi

  if [[ ${this_project_area} ]]; then
    this_area_id=$(database_silent "SELECT id FROM area WHERE name='${this_project_area}'")
    if [[ ! $this_area_id ]] ; then
      echo "Error: invalid area name."
      exit 1
    fi
  fi

  # Inserting
  database_run "INSERT INTO project (name, area_id, deadline) VALUES (${this_project_name}, ${this_area_id:-NULL}, ${this_project_deadline:-NULL});"
  
}

function projectDelete() {
  this_project_id="$1"

  if [[ $this_project_id ]] ; then
    database_run "DELETE FROM project WHERE id = $this_project_id;"
  else
    echo "Error: missing project ID."
    exit 1
  fi
}

function projectHelp() {
  echo "${help_banner} - Projects"
  echo
  echo "Actions:"
  echo "  $(basename $0) add --name PROJECT_NAME [--area AREA_NAME] [--deadline DATE]"
  echo "  $(basename $0) delete PROJECT_ID"
  echo "  $(basename $0) help (this message)"
  echo "  $(basename $0) list"
  echo "  $(basename $0) rename OLD_PROJECT_NAME NEW_PROJECT_NAME"
  echo
}

function projectList() {
  database_run "SELECT * FROM project_view ORDER BY deadline ASC NULLS LAST"
}

function projectMain() {
  usr_command="$1"
  
  case "${usr_command}" in
    "add")
      shift
      projectAdd "$@"
      ;;
    "delete")
      shift
      projectDelete "$1"
      ;;
    "help")
      projectHelp
      ;;
    "list")
      projectList
      ;;
    "rename")
      shift
      projectRename "$@"
      ;;
    *)
      projectHelp
      ;;
  esac
}

function projectRename() {
  this_old_project_name="$1"
  this_new_project_name="$2"

  if [[ $this_new_project_name ]] ; then
    database_run "UPDATE project SET name='$this_new_project_name' WHERE name='$this_old_project_name';"
  else
    echo "Error: missing required args."
    exit 1
  fi
}
