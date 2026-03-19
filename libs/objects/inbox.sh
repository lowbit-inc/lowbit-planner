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
    inbox_add_help
  fi

  this_inbox_item="${user_args}"

  database_run box "INSERT INTO inbox (name) VALUES ('$this_inbox_item');" ; database_run_rc=$?

  if [[ $database_run_rc -eq 0 ]] ; then
    log_print info "Item added to inbox"
  else
    log_print error "Failed to add item to inbox"
  fi

}

function inbox_add_help() {
  log_print debug "Getting help message: inbox add"
  printf "${color_bold}${system_long_name} - Inbox Add${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Add items to the inbox.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${color_underline}${system_basename}${color_reset} ${color_bold}${color_red}inbox ${color_green}add ${color_bold}${color_blue}ITEM_NAME${color_reset}\n"
  printf "\n"
  printf "${color_bold}ARGUMENTS:${color_reset}\n"
  printf "  ITEM_NAME  ${color_gray}Item or idea to add to inbox${color_reset}\n"
  printf "\n"
  exit 0
}

function inbox_delete() {

  log_print debug "Starting Inbox Delete"

  if [[ "${1}" ]]; then
    user_args="$@"
    log_print debug "User args: ${user_args}"
  else
    log_print debug "No user arg provided - calling help message"
    inbox_delete_help
  fi

  this_inbox_id="$1" && validate_database_id inbox "${this_inbox_id}"

  database_run box "DELETE FROM inbox WHERE id = $this_inbox_id;" ; database_run_rc=$?

  if [[ $database_run_rc -eq 0 ]] ; then
    log_print info "Item ${this_inbox_id} deleted from inbox"
  else
    log_print error "Failed to delete item from inbox"
  fi

}

function inbox_delete_help() {
  log_print debug "Getting help message: inbox delete"
  printf "${color_bold}${system_long_name} - Inbox Delete${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Removes items from the inbox.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${color_underline}${system_basename}${color_reset} ${color_bold}${color_red}inbox ${color_green}delete ${color_bold}${color_blue}ITEM_ID${color_reset}\n"
  printf "\n"
  printf "${color_bold}ARGUMENTS:${color_reset}\n"
  printf "  ITEM_ID  ${color_gray}ID of inbox item to delete${color_reset}\n"
  printf "\n"
  exit 0
}

function inbox_help() {
  log_print debug "Getting help message: inbox"
  printf "${color_bold}${system_long_name} - Inbox${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  The place to capture your ideas.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${color_underline}${system_basename}${color_reset} ${color_bold}${color_red}inbox ${color_green}SUBCOMMAND${color_reset} ${color_gray}[${color_bold}${color_blue}ARGUMENTS${color_reset}${color_gray}]${color_reset}\n"
  printf "\n"
  printf "${color_bold}SUBCOMMANDS:${color_reset}\n"
  printf "  add\n"
  printf "  clarify\n"
  printf "  delete\n"
  printf "  list\n"
  printf "\n"
  exit 0
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
    inbox_help
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
      inbox_help
      ;;
    "list")
      inbox_list
      ;;
    *)
      log_print warn "Unknown command (${user_arg})"
      inbox_help
      ;;
  esac
}
