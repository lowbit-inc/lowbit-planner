#!/bin/bash
purposeFile="purpose.txt"
purposePath="${database_dir}/${purposeFile}"

function purposeCheck(){
  if [[ ! -f "${database_dir}/${purposeFile}" ]] ; then
    echo "Purpose file not found. Initializing..."
    purposeInit
    echo
  fi
}

function purposeHelp() {
  echo "${help_banner} - Purpose"
  echo
  echo "Actions:"
  echo "  ${help_basename} edit"
  echo "  ${help_basename} help (this message)"
  echo "  ${help_basename} view"
  echo
}

function purposeInit() {

  touch "${purposePath}"
  echo "# Principles \n" > "${purposePath}"

}

function purposeList() {
  database_run "SELECT * FROM purpose_view ORDER BY name ASC"
}

function purposeMain() {
  usr_command="$1"
  
  case "${usr_command}" in
    "edit")
      shift
      purposeDelete "$1"
      ;;
    "help")
      purposeHelp
      ;;
    "view")
      purposeList
      ;;
    *)
      purposeHelp
      ;;
  esac
}