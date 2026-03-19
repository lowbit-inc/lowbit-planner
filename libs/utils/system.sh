#!/bin/bash

##############
# Properties #
##############

system_short_name="lowbit-planner"
system_long_name="Lowbit Planner"
system_version="0.1.0"
system_basename="$(basename $0)"

###########
# Methods #
###########

function system_get_help() {
  log_print debug "Getting help message: main"
  printf "${color_bold}${system_long_name} - Main Help${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  A ${color_underline}life planner${color_reset} tool to use without leaving the terminal.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${color_underline}${system_basename}${color_reset} ${color_bold}${color_red}COMMAND${color_reset} ${color_gray}[${color_bold}${color_green}SUBCOMMAND${color_reset}${color_gray}] [${color_bold}${color_blue}ARGUMENTS${color_reset}${color_gray}]${color_reset}\n"
  printf "\n"
  printf "${color_bold}SYSTEM COMMANDS:${color_reset}\n"
  printf "  help            ${color_gray}This help message${color_reset}\n"
  printf "  version         ${color_gray}Get CLI version${color_reset}\n"
  printf "\n"
  printf "${color_bold}WORKFLOW COMMANDS:${color_reset}\n"
  printf "  capture ${color_blue}IDEA${color_reset}    ${color_gray}Capture ideas to the inbox${color_reset}\n"
  printf "\n"
  printf "${color_bold}OBJECT COMMANDS:${color_reset}\n"
  printf "  inbox           ${color_gray}Manage inbox items${color_reset}\n"
  printf "\n"
  exit 0
}

function system_get_version() {
  echo "${system_short_name} ${system_version}"
}
