#!/bin/bash

function visionAdd() {

  # Getting args
  while [[ "$@" ]] ; do
    this_arg="${1}"

    case "${this_arg}" in
      "--area")
        shift
        if [[ "${1}" ]] ; then
          this_vision_area="${1}"
        else
          echo "Error: missing vision area"
          exit 1
        fi
        ;;
      "--name")
        shift
        if [[ "${1}" ]] ; then
          this_vision_name="'${1}'"
        else
          echo "Error: missing vision name"
          exit 1
        fi
        ;;
    esac

    shift
  done

  # Validating input
  if [[ ! ${this_vision_name} ]]; then
    echo "Error: missing vision name"
    exit 1
  fi

  if [[ ${this_vision_area} ]]; then
    this_area_id=$(database_silent "SELECT id FROM area WHERE name='${this_vision_area}'")
    if [[ ! $this_area_id ]] ; then
      echo "Error: invalid area name."
      exit 1
    fi
  fi

  # Inserting
  database_run "INSERT INTO vision (name, area_id) VALUES (${this_vision_name}, ${this_area_id:-NULL});"
  
}

function visionDelete() {
  this_vision_id="$1"

  if [[ $this_vision_id ]] ; then
    database_run "DELETE FROM vision WHERE id = $this_vision_id;"
  else
    echo "Error: missing vision ID."
    exit 1
  fi
}

function visionHelp() {
  echo "${help_banner} - Visions"
  echo
  echo "Actions:"
  echo "  ${help_basename} add --name VISION_NAME [--area AREA_NAME]"
  echo "  ${help_basename} delete VISION_ID"
  echo "  ${help_basename} help (this message)"
  echo "  ${help_basename} list"
  echo "  ${help_basename} rename OLD_VISION_NAME NEW_VISION_NAME"
  echo
}

function visionList() {
  database_run "SELECT * FROM vision_view ORDER BY name ASC"
}

function visionMain() {
  usr_command="$1"
  
  case "${usr_command}" in
    "add")
      shift
      visionAdd "$@"
      ;;
    "delete")
      shift
      visionDelete "$1"
      ;;
    "help")
      visionHelp
      ;;
    "list")
      visionList
      ;;
    "rename")
      shift
      visionRename "$@"
      ;;
    *)
      visionHelp
      ;;
  esac
}

function visionRename() {
  this_old_vision_name="$1"
  this_new_vision_name="$2"

  if [[ $this_new_vision_name ]] ; then
    database_run "UPDATE vision SET name='$this_new_vision_name' WHERE name='$this_old_vision_name';"
  else
    echo "Error: missing required args."
    exit 1
  fi
}
