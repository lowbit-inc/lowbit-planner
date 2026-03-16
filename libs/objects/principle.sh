#!/bin/bash
principleFile="principle.txt"
principlePath="${database_dir}/${principleFile}"

function principleCheck(){
  if [[ ! -f "${principlePath}" ]] ; then
    echo "Principle file not found. Initializing..."
    principleInit
    echo
  fi
}

function principleHelp() {
  echo "${help_banner} - Principles"
  echo
  echo "Actions:"
  echo "  ${help_basename} edit"
  echo "  ${help_basename} help (this message)"
  echo "  ${help_basename} view"
  echo
}

function principleInit() {

  touch "${principlePath}"
  echo "# Principles \n" > "${principlePath}"

}

function principleList() {
  database_run "SELECT * FROM principle_view ORDER BY name ASC"
}

function principleMain() {
  usr_command="$1"
  
  case "${usr_command}" in
    "edit")
      shift
      principleDelete "$1"
      ;;
    "help")
      principleHelp
      ;;
    "view")
      principleList
      ;;
    *)
      principleHelp
      ;;
  esac
}