#!/bin/bash

function help_inbox() {
  log_message debug "Getting help message: inbox"
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
  printf "  edit\n"
  printf "  list\n"
  printf "\n"
  exit 0
}

function help_inbox_add() {
  log_message debug "Getting help message: inbox add"
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
