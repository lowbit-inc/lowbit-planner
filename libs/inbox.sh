#!/bin/bash

function inboxAdd() {

  this_inbox_item="$@"

  if [[ $this_inbox_item ]] ; then
    database_run "INSERT INTO inbox (name) VALUES ('$this_inbox_item');"
  else
    echo "Error: missing inbox item name."
    exit 1
  fi
}

function inboxDelete() {
  this_inbox_id="$1"

  if [[ $this_inbox_id ]] ; then
    database_run "DELETE FROM inbox WHERE id = $this_inbox_id;"
  else
    echo "Error: missing inbox item ID."
    exit 1
  fi
}

function inboxHelp() {
  echo "${help_banner} - Inbox"
  echo
  echo "Actions:"
  echo "  ${help_basename} add ITEM_NAME"
  echo "  ${help_basename} clarify"
  echo "  ${help_basename} delete ITEM_ID"
  echo "  ${help_basename} help (this message)"
  echo "  ${help_basename} list"
  echo
}

function inboxList() {
  database_run "SELECT * FROM inbox"
}

function inboxMain() {
  usr_command="$1"
  
  case "${usr_command}" in
    "add")
      shift
      inboxAdd "$@"
      ;;
    "clarify")
      clarify
      ;;
    "delete")
      shift
      inboxDelete "$1"
      ;;
    "help")
      inboxHelp
      ;;
    "list")
      inboxList
      ;;
    *)
      inboxHelp
      ;;
  esac
}
