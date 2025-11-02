#!/bin/bash

function recurringHelp() {

  echo "${help_banner} - Recurring Tasks"
  echo
  echo "Actions:"
  echo "  $(basename $0) add --name TASK_NAME --recur FREQUENCY"
  echo "  $(basename $0) complete TASK_ID"
  echo "  $(basename $0) delete TASK_ID"
  echo "  $(basename $0) help (this message)"
  echo "  $(basename $0) list"
  echo "  $(basename $0) rename OLD_TASK_NAME NEW_TASK_NAME"
  echo
  echo "Frequencies:"
  echo "  daily"
  echo "  weekly"
  echo "  monthly"
  echo "  quarterly"
  echo "  biannual"
  echo "  yearly"
  echo

}

function recurringList() {

  database_run "SELECT * FROM recurring;"

}

function recurringMain() {

  case $1 in
    "add")
      shift
      recurringAdd "$@"
      ;;
    "delete")
      shift
      recurringDelete "$@"
      ;;
    "list")
      recurringList
      ;;
    *)
      recurringHelp
      ;;
  esac

}
