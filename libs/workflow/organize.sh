#!/bin/bash

function organize_main() {

  log_print debug "Starting Organize workflow"

  if [[ ! "${1}" ]]; then
    help_get_message organize
  fi

  this_level="${1}"

  case "${this_level}" in
    "ground")
      organize_ground
      ;;
    "horizon1"|"h1")
      organize_horizon1
      ;;
    "horizon2"|"h2")
      organize_horizon2
      ;;
    "horizon3"|"h3")
      organize_horizon3
      ;;
    "horizon4"|"h4")
      organize_horizon4
      ;;
    "horizon5"|"h5")
      organize_horizon5
      ;;
    "all")
      organize_ground
      organize_horizon1
      organize_horizon2
      organize_horizon3
      organize_horizon4
      organize_horizon5
      ;;
    *)
      log_print warn "Unknown level '${this_level}'"
      help_get_message organize
      ;;
  esac
}

function organize_print_header() {
  local this_title="${1}"
  printf "${color_bold}${color_cyan}── ${this_title} ──${color_reset}\n"
  printf "\n"
}

function organize_ground() {

  printf "${color_bold}${color_bright_blue}═══ Ground Level ═══${color_reset}\n"
  printf "\n"

  organize_print_header "Inbox"
  local this_inbox=$(database_run box "SELECT * FROM inbox_view")
  if [[ -n "${this_inbox}" ]]; then
    echo "${this_inbox}"
  else
    printf "  ${color_gray}(empty)${color_reset}\n"
  fi
  printf "\n"

  organize_print_header "Tasks"
  local this_tasks=$(database_run box "SELECT * FROM tasks_view WHERE status != 'Done'")
  if [[ -n "${this_tasks}" ]]; then
    echo "${this_tasks}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"

  organize_print_header "Recurring"
  local this_recurrings=$(database_run box "SELECT * FROM recurrings_view WHERE status != 'Done'")
  if [[ -n "${this_recurrings}" ]]; then
    echo "${this_recurrings}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"

  organize_print_header "Habits"
  local this_habits=$(database_run box "SELECT * FROM habits_view WHERE status != 'Done'")
  if [[ -n "${this_habits}" ]]; then
    echo "${this_habits}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"

  organize_print_header "Collections"
  local this_collections=$(database_run box "SELECT * FROM collections_view")
  if [[ -n "${this_collections}" ]]; then
    echo "${this_collections}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"

  organize_print_header "Collection Items"
  local this_items=$(database_run box "SELECT * FROM collection_items_view WHERE status != 'Done'")
  if [[ -n "${this_items}" ]]; then
    echo "${this_items}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
}

function organize_horizon1() {

  printf "${color_bold}${color_bright_blue}═══ Horizon 1 - Projects ═══${color_reset}\n"
  printf "\n"

  local this_projects=$(database_run box "SELECT * FROM projects_view WHERE status != 'Done'")
  if [[ -n "${this_projects}" ]]; then
    echo "${this_projects}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
}

function organize_horizon2() {

  printf "${color_bold}${color_bright_blue}═══ Horizon 2 - Areas of Responsibility ═══${color_reset}\n"
  printf "\n"

  local this_areas=$(database_run box "SELECT * FROM areas_view")
  if [[ -n "${this_areas}" ]]; then
    echo "${this_areas}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
}

function organize_horizon3() {

  printf "${color_bold}${color_bright_blue}═══ Horizon 3 - Goals ═══${color_reset}\n"
  printf "\n"

  local this_goals=$(database_run box "SELECT * FROM goals_view WHERE status != 'Done'")
  if [[ -n "${this_goals}" ]]; then
    echo "${this_goals}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
}

function organize_horizon4() {

  printf "${color_bold}${color_bright_blue}═══ Horizon 4 - Visions ═══${color_reset}\n"
  printf "\n"

  local this_visions=$(database_run box "SELECT * FROM visions_view WHERE status != 'Done'")
  if [[ -n "${this_visions}" ]]; then
    echo "${this_visions}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
}

function organize_horizon5() {

  printf "${color_bold}${color_bright_blue}═══ Horizon 5 - Purpose & Principles ═══${color_reset}\n"
  printf "\n"

  organize_print_header "Purposes"
  local this_purposes=$(database_run box "SELECT * FROM purposes_view")
  if [[ -n "${this_purposes}" ]]; then
    echo "${this_purposes}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"

  organize_print_header "Principles"
  local this_principles=$(database_run box "SELECT * FROM principles_view")
  if [[ -n "${this_principles}" ]]; then
    echo "${this_principles}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
}
