#!/bin/bash

##############
# Properties #
##############

system_short_name="lowbit-planner"
system_long_name="Lowbit Planner"
system_version="0.2.1-dev"
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
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS] ${color_red}<COMMAND> ${color_green}[SUBCOMMAND] ${color_blue}[ARGS]${color_reset}\n"
  printf "\n"
  printf "${color_bold}SYSTEM COMMANDS:${color_reset}\n"
  printf "  help            ${color_gray}This help message${color_reset}\n"
  printf "  install         ${color_gray}Installs this CLI to /usr/local/bin/plan${color_reset}\n"
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

function system_install() {
  log_print user "This will install ${system_short_name} as ${color_underline}plan${color_reset} in ${color_bold}/usr/local/bin${color_reset} using ${color_bold}sudo${color_reset}. Proceed?"
  ln -s $SCRIPT_DIR/$system_basename /usr/local/bin/plan
}