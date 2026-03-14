#!/bin/bash

function area_add() {
  this_area_name="$@"

  if [[ $this_area_name ]] ; then
    database_run "INSERT INTO area (name) VALUES ('$this_area_name');"
  else
    echo "Error: missing area name."
    exit 1
  fi
}

function area_delete() {
  this_area_name="$1"

  if [[ $this_area_name ]] ; then
    database_run "DELETE FROM area WHERE name = '$this_area_name';"
  else
    echo "Error: missing area name."
    exit 1
  fi
}

function area_help() {
  printf "${system_banner} - Areas\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Manage ${color_underline}Areas${color_reset} of life (${color_underline}Horizon 2${color_reset} in ${color_underline}GTD${color_reset})\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${color_underline}${system_basename}${color_reset} ${color_bold}${color_red}area${color_reset} ${color_gray}[${color_bold}${color_green}SUBCOMMAND${color_reset}${color_gray}] [${color_bold}${color_blue}ARGUMENTS${color_reset}${color_gray}]${color_reset}\n"
  printf "\n"
  printf "${color_bold}SUBCOMMANDS:${color_reset}\n"
  printf "  add\n"
  printf "\n"
}

function area_list() {
  database_run "SELECT name FROM area ORDER BY name"
}

function area_main() {
  usr_command="$1"
  
  case "${usr_command}" in
    "add")
      shift
      areaAdd "$@"
      ;;
    "delete")
      shift
      area_delete "$1"
      ;;
    "help")
      area_help
      ;;
    "list")
      area_list
      ;;
    "rename")
      shift
      area_rename "$@"
      ;;
    *)
      area_help
      ;;
  esac
}

function area_rename() {
  this_old_area_name="$1"
  this_new_area_name="$2"

  if [[ $this_new_area_name ]] ; then
    database_run "UPDATE area SET name='$this_new_area_name' WHERE name='$this_old_area_name';"
  else
    echo "Error: missing required args."
    exit 1
  fi
}
