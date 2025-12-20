#!/bin/bash

function inbox_add() {

  log_message debug "Starting Inbox Add"

  if [[ "${1}" ]]; then
    user_arg="${1}" && log_message debug "User arg: ${user_arg}"
  else
    log_message debug "No user arg provided - calling help message"
    help_inbox_add
  fi

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
    user_arg="${1}" && log_message debug "User arg: ${user_arg}"
  else
    log_message debug "No User arg provided - calling help message"
    help_inbox
  fi

  case "${user_arg}" in
    "add")
      shift
      inbox_add "$@"
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
      log_message warn "Unknown command (${user_arg})"
      help_inbox
      ;;
  esac
}
