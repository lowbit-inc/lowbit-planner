#!/bin/bash

function areaAdd() {
  this_area_name="$@"

  if [[ $this_area_name ]] ; then
    database_run "INSERT INTO area (name) VALUES ('$this_area_name');"
  else
    echo "Error: missing area name."
    exit 1
  fi
}

function areaDelete() {
  this_area_name="$1"

  if [[ $this_area_name ]] ; then
    database_run "DELETE FROM area WHERE name = '$this_area_name';"
  else
    echo "Error: missing area name."
    exit 1
  fi
}

function areaHelp() {
  echo "${help_banner} - Areas"
  echo
  echo "Actions:"
  echo "  ${help_basename} add AREA_NAME"
  echo "  ${help_basename} delete AREA_NAME"
  echo "  ${help_basename} help (this message)"
  echo "  ${help_basename} list"
  echo "  ${help_basename} rename OLD_AREA_NAME NEW_AREA_NAME"
  echo
}

function areaList() {
  database_run "SELECT name FROM area ORDER BY name"
}

function areaMain() {
  usr_command="$1"
  
  case "${usr_command}" in
    "add")
      shift
      areaAdd "$@"
      ;;
    "delete")
      shift
      areaDelete "$1"
      ;;
    "help")
      areaHelp
      ;;
    "list")
      areaList
      ;;
    "rename")
      shift
      areaRename "$@"
      ;;
    *)
      areaHelp
      ;;
  esac
}

function areaRename() {
  this_old_area_name="$1"
  this_new_area_name="$2"

  if [[ $this_new_area_name ]] ; then
    database_run "UPDATE area SET name='$this_new_area_name' WHERE name='$this_old_area_name';"
  else
    echo "Error: missing required args."
    exit 1
  fi
}
