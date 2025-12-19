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

function inboxList() {
  database_run "SELECT * FROM inbox"
}

function inbox_main() {

  log_message debug "Starting Inbox Main"

  if [[ "${1}" ]]; then
    user_command="${1}" && log_message debug "User command: ${user_command}"
  else
    log_message debug "No user command provided - calling help message"
    help_inbox
  fi

  case "${user_command}" in
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
      help_inbox
      ;;
    "list")
      inboxList
      ;;
    *)
      log_message warn "Unknown command (${user_command})"
      help_inbox
      ;;
  esac
}
