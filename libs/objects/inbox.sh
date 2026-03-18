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
  printf "  ${color_underline}${system_basename}${color_reset} ${color_bold}${color_red}inbox ${color_green}add ${color_blue}ITEM_NAME${color_reset}\n"
  printf "\n"
  printf "${color_bold}ARGUMENTS:${color_reset}\n"
  printf "  ${color_gray}(no supported args)${color_reset}\n"
  printf "\n"
  exit 0
}

function inboxDelete() {
  this_inbox_id="$1"

  if [[ $this_inbox_id ]] ; then
    database_run "box" "DELETE FROM inbox WHERE id = $this_inbox_id;"
  else
    echo "Error: missing inbox item ID."
    exit 1
  fi
}

function inbox_help() {
  log_print debug "Getting help message: inbox"
  printf "${color_bold}${system_long_name} - Inbox${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  The place to capture all of your ideas.\n"
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

function inboxList() {
  database_run "box" "SELECT * FROM inbox"
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
      inbox_delete "$1"
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
