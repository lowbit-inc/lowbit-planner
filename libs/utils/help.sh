#!/bin/bash

##############
# Properties #
##############

###########
# Methods #
###########

function help_get_message() {

  # Getting input args
  this_help_message="$1"

  # Logging debug info
  log_print debug "Getting help message for: $this_help_message"

  # Getting message
  help_print_"${this_help_message}"

  # Exiting always as 0 after help messages
  exit 0
}

function help_print_inbox() {
  printf "${color_bold}${system_long_name} - Inbox${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  The place to capture your ideas.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} inbox ${color_green}SUBCOMMAND ${color_blue}[ARGS]${color_reset}\n"
  printf "\n"
  printf "${color_bold}SUBCOMMANDS:${color_reset}\n"
  printf "  add ${color_blue}ITEM_NAME${color_reset}\n"
  printf "  clarify\n"
  printf "  delete ${color_blue}ITEM_ID${color_reset}\n"
  printf "  list\n"
  printf "\n"
}

function help_print_inbox_add() {
  printf "${color_bold}${system_long_name} - Inbox Add${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Add items to the inbox.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} inbox add ${color_blue}ITEM_NAME${color_reset}\n"
  printf "\n"
  printf "${color_bold}ARGUMENTS:${color_reset}\n"
  printf "  ${color_blue}ITEM_NAME  ${color_gray}Item or idea to add to inbox${color_reset}\n"
  printf "\n"
}

function help_print_inbox_delete() {
  printf "${color_bold}${system_long_name} - Inbox Delete${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Removes items from the inbox.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} inbox delete ${color_blue}ITEM_ID${color_reset}\n"
  printf "\n"
  printf "${color_bold}ARGUMENTS:${color_reset}\n"
  printf "  ${color_blue}ITEM_ID  ${color_gray}ID of inbox item to delete${color_reset}\n"
  printf "\n"
}
function help_print_main() {
  printf "${color_bold}${system_long_name} - Help${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  A ${color_underline}life planner${color_reset} tool to use without leaving the terminal.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS] ${color_red}<COMMAND> ${color_green}[SUBCOMMAND] ${color_blue}[ARGS]${color_reset}\n"
  printf "\n"
  printf "${color_bold}SYSTEM COMMANDS:${color_reset}\n"
  printf "  help           ${color_gray}This help message${color_reset}\n"
  printf "  install        ${color_gray}Installs this CLI to /usr/local/bin/plan${color_reset}\n"
  printf "  version        ${color_gray}Get CLI version${color_reset}\n"
  printf "\n"
  printf "${color_bold}WORKFLOW COMMANDS:${color_reset}\n"
  printf "  capture ${color_blue}IDEA${color_reset}   ${color_gray}1. Capture ideas to the inbox${color_reset}\n"
  printf "\n"
  printf "${color_bold}OBJECT COMMANDS:${color_reset}\n"
  printf "  inbox          ${color_gray}Manage inbox items  (Ground)${color_reset}\n"
  printf "  task           ${color_gray}Manage next actions (Ground)${color_reset}\n"
  printf "  project        ${color_gray}Manage projects (Horizon 1)${color_reset}\n"
  printf "  area           ${color_gray}Manage areas of responsibility (Horizon 2)${color_reset}\n"
  printf "\n"
}

function help_print_area() {
  printf "${color_bold}${system_long_name} - Area${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Manage areas of responsibility (GTD Horizon 2).\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} area ${color_green}SUBCOMMAND ${color_blue}[ARGS]${color_reset}\n"
  printf "\n"
  printf "${color_bold}SUBCOMMANDS:${color_reset}\n"
  printf "  add ${color_blue}AREA_NAME [ARGS]${color_reset}\n"
  printf "  delete ${color_blue}AREA_NAME${color_reset}\n"
  printf "  edit ${color_blue}AREA_NAME [ARGS]${color_reset}\n"
  printf "  list\n"
  printf "\n"
}

function help_print_area_add() {
  printf "${color_bold}${system_long_name} - Area Add${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Add a new area of responsibility.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} area add ${color_blue}AREA_NAME [ARGS]${color_reset}\n"
  printf "\n"
  printf "${color_bold}REQUIRED ARGUMENTS:${color_reset}\n"
  printf "  ${color_blue}AREA_NAME                   ${color_gray}Name of the area${color_reset}\n"
  printf "\n"
  printf "${color_bold}OPTIONAL ARGUMENTS:${color_reset}\n"
  printf "  --description ${color_blue}DESC          ${color_gray}Description of the area${color_reset}\n"
  printf "\n"
}

function help_print_area_delete() {
  printf "${color_bold}${system_long_name} - Area Delete${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Delete an area of responsibility.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} area delete ${color_blue}AREA_NAME${color_reset}\n"
  printf "\n"
  printf "${color_bold}REQUIRED ARGUMENTS:${color_reset}\n"
  printf "  ${color_blue}AREA_NAME                   ${color_gray}Name of the area to delete${color_reset}\n"
  printf "\n"
}

function help_print_area_edit() {
  printf "${color_bold}${system_long_name} - Area Edit${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Edit an existing area of responsibility.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} area edit ${color_blue}AREA_NAME [ARGS]${color_reset}\n"
  printf "\n"
  printf "${color_bold}REQUIRED ARGUMENTS:${color_reset}\n"
  printf "  ${color_blue}AREA_NAME                   ${color_gray}Name of the area to edit${color_reset}\n"
  printf "\n"
  printf "${color_bold}OPTIONAL ARGUMENTS:${color_reset}\n"
  printf "  --name        ${color_blue}NEW_NAME      ${color_gray}New name for the area${color_reset}\n"
  printf "  --description ${color_blue}DESC          ${color_gray}New description for the area${color_reset}\n"
  printf "\n"
}

function help_print_task() {
  printf "${color_bold}${system_long_name} - Task${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Manage tasks (next actions).\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} task ${color_green}SUBCOMMAND ${color_blue}[ARGS]${color_reset}\n"
  printf "\n"
  printf "${color_bold}SUBCOMMANDS:${color_reset}\n"
  printf "  add ${color_blue}TASK_NAME [ARGS]${color_reset}\n"
  printf "  complete ${color_blue}TASK_ID${color_reset}\n"
  printf "  delete ${color_blue}TASK_ID${color_reset}\n"
  printf "  edit ${color_blue}TASK_ID${color_reset}\n"
  printf "  list ${color_blue}[ARGS]${color_reset}\n"
  printf "  search ${color_blue}PATTERN${color_reset}\n"
  printf "  start ${color_blue}TASK_ID${color_reset}\n"
  printf "  stop ${color_blue}TASK_ID${color_reset}\n"
  printf "\n"
}

function help_print_task_add() {
  printf "${color_bold}${system_long_name} - Task Add${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Add items to the task list.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} task add ${color_blue}TASK_NAME [ARGS]${color_reset}\n"
  printf "\n"
  printf "${color_bold}REQUIRED ARGUMENTS:${color_reset}\n"
  printf "  ${color_blue}TASK_NAME                   ${color_gray}Name or description${color_reset}\n"
  printf "\n"
  printf "${color_bold}OPTIONAL ARGUMENTS:${color_reset}\n"
  printf "  --start-date ${color_blue}YYYY-MM-DD     ${color_gray}When task is able to be done${color_reset}\n"
  printf "  --due-date   ${color_blue}YYYY-MM-DD     ${color_gray}Deadline${color_reset}\n"
  printf "  --project    ${color_blue}PROJECT_NAME   ${color_gray}Related project${color_reset}\n"
  printf "\n"
}

function help_print_project() {
  printf "${color_bold}${system_long_name} - Project${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Manage projects (GTD Horizon 1).\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} project ${color_green}SUBCOMMAND ${color_blue}[ARGS]${color_reset}\n"
  printf "\n"
  printf "${color_bold}SUBCOMMANDS:${color_reset}\n"
  printf "  add      ${color_blue}PROJECT_NAME [ARGS]${color_reset}\n"
  printf "  complete ${color_blue}PROJECT_ID${color_reset}\n"
  printf "  delete   ${color_blue}PROJECT_ID${color_reset}\n"
  printf "  edit     ${color_blue}PROJECT_ID [ARGS]${color_reset}\n"
  printf "  list\n"
  printf "  search   ${color_blue}PATTERN${color_reset}\n"
  printf "  start    ${color_blue}PROJECT_ID${color_reset}\n"
  printf "  stop     ${color_blue}PROJECT_ID${color_reset}\n"
  printf "\n"
}

function help_print_project_add() {
  printf "${color_bold}${system_long_name} - Project Add${color_reset}\n"
  printf "\n"
  printf "${color_bold}DESCRIPTION:${color_reset}\n"
  printf "  Add a new project.\n"
  printf "\n"
  printf "${color_bold}USAGE:${color_reset}\n"
  printf "  ${system_basename} ${color_gray}[GLOBAL_ARGS]${color_reset} project add ${color_blue}PROJECT_NAME${color_reset} --area ${color_blue}AREA_NAME [ARGS]${color_reset}\n"
  printf "\n"
  printf "${color_bold}REQUIRED ARGUMENTS:${color_reset}\n"
  printf "  ${color_blue}PROJECT_NAME                ${color_gray}Name of the project${color_reset}\n"
  printf "  --area       ${color_blue}AREA_NAME     ${color_gray}Area this project belongs to${color_reset}\n"
  printf "\n"
  printf "${color_bold}OPTIONAL ARGUMENTS:${color_reset}\n"
  printf "  --start-date ${color_blue}YYYY-MM-DD    ${color_gray}When the project starts${color_reset}\n"
  printf "  --due-date   ${color_blue}YYYY-MM-DD    ${color_gray}Deadline for the project${color_reset}\n"
  printf "\n"
}
