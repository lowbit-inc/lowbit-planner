#!/bin/bash

function recurringHelp() {

  echo "${help_banner} - Recurring Tasks"
  echo
  echo "Commands:"
  echo "  add --name task_name --recur FREQUENCY"
  echo "  delete task_id"
  echo "  help (this message)"
  echo "  list"
  echo
  echo "Frequencies:"
  echo "  daily"
  echo "  weekly"
  echo "  monthly"
  echo "  quarterly"
  echo "  biannual"
  echo "  yearly"

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
