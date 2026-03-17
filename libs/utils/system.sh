#!/bin/bash

##############
# Properties #
##############

system_short_name="lowbit-planner"
system_long_name="Lowbit Planner"
system_banner="Lowbit Planner"
system_version="v0.2.0-dev"
system_basename="$(basename $0)"

###########
# Methods #
###########

function system_get_help() {
  
  log_message debug "Getting help message: main"
  printf "${color_bold}${system_banner} - Main Help${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  A ${color_underline}life planner${color_reset} tool to use without leaving the terminal.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${color_underline}${system_basename}${color_reset} ${color_bold}${color_red}COMMAND${color_reset} ${color_gray}[${color_bold}${color_green}SUBCOMMAND${color_reset}${color_gray}] [${color_bold}${color_blue}ARGUMENTS${color_reset}${color_gray}]${color_reset}\n"
  printf "\n"
  printf "${color_bold}COMMANDS:${color_reset}\n"
  printf "\n"
  exit 0
}

function system_get_version() {
  echo "${system_banner} - Version: ${system_version}"
}
