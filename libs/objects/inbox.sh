#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function inbox_add() {

  log_print debug "Starting Inbox Add"

  if [[ "${1}" ]]; then
    user_args="$@"
    log_print debug "User args: ${user_args}"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message inbox_add
  fi

  this_inbox_item="${user_args}"

  generic_add "inbox" "name" "'${this_inbox_item}'" "${this_inbox_item}"
  # database_run box "INSERT INTO inbox (name) VALUES ('$this_inbox_item');" ; database_run_rc=$?

  # if [[ $database_run_rc -eq 0 ]] ; then
  #   log_print info "Item added to inbox (${this_inbox_item})"
  # else
  #   log_print error "Failed to add item to inbox"
  # fi

}

function inbox_delete() {

  # Start
  log_print debug "Starting Inbox Delete"

  # Checking args
  if [[ "${1}" ]]; then
    user_args="$@"
    log_print debug "User args: ${user_args}"
  else
    log_print debug "No user arg provided - calling help message"
    help_get_message inbox_delete
  fi

  # Getting args
  this_inbox_id="$1" && validate_database_id inbox "${this_inbox_id}"

  # Extra information
  this_inbox_item=$(database_run csv "SELECT name FROM inbox WHERE id = ${this_inbox_id};")

  generic_delete "inbox" "id" "${this_inbox_id}" "${this_inbox_item}"

}

function inbox_list() {
  database_run "box" "SELECT * FROM inbox_view"
}

function inbox_main() {

  log_print debug "Starting Inbox Main"

  if [[ "${1}" ]]; then
    user_arg="${1}" ; shift
    log_print debug "User arg: ${user_arg}"
  else
    log_print debug "No User arg provided - calling help message"
    help_get_message inbox
  fi

  case "${user_arg}" in
    "add")
      inbox_add "$@"
      ;;
    "clarify")
      clarify_main
      ;;
    "delete")
      inbox_delete "$@"
      ;;
    "help")
      help_get_message inbox
      ;;
    "list")
      generic_list inbox_view
      ;;
    *)
      log_print warn "Unknown command (${user_arg})"
      help_get_message inbox
      ;;
  esac
}
