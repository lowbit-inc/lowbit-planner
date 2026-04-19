#!/bin/bash

##############
# Properties #
##############

# Communication between TUI layers (set by callees, read by callers):
#   this_organize_choice - "ground" | "horizon1"..."horizon5" | "all" | "quit" | ""

###########
# Layer 1 #
# Main loop
###########

function organize_main() {
  log_print debug "Starting Organize workflow"

  while true; do
    this_organize_choice=""
    organize_screen_menu
    case "${this_organize_choice}" in
      quit|"")   return 0 ;;
      ground)    organize_show_level organize_ground    "Ground"    ;;
      horizon1)  organize_show_level organize_horizon1  "Horizon 1" ;;
      horizon2)  organize_show_level organize_horizon2  "Horizon 2" ;;
      horizon3)  organize_show_level organize_horizon3  "Horizon 3" ;;
      horizon4)  organize_show_level organize_horizon4  "Horizon 4" ;;
      horizon5)  organize_show_level organize_horizon5  "Horizon 5" ;;
      all)       organize_show_all ;;
    esac
    # If the level viewer got EOF, propagate quit out of the outer loop
    if [[ "${this_organize_choice}" == "quit" ]]; then
      return 0
    fi
  done
}

###########
# Layer 2 #
# Menu TUI
###########

function organize_screen_menu() {
  local this_choice
  while true; do
    clear
    printf "${color_bold}${system_long_name} - Organize${color_reset}\n\n"
    printf "  Choose a horizon:\n\n"
    printf "  ${color_green}(g)${color_reset} Ground     ${color_gray}Inbox, Tasks, Recurring, Habits, Collections, Items${color_reset}\n"
    printf "  ${color_green}(1)${color_reset} Horizon 1  ${color_gray}Projects${color_reset}\n"
    printf "  ${color_green}(2)${color_reset} Horizon 2  ${color_gray}Areas${color_reset}\n"
    printf "  ${color_green}(3)${color_reset} Horizon 3  ${color_gray}Goals${color_reset}\n"
    printf "  ${color_green}(4)${color_reset} Horizon 4  ${color_gray}Visions${color_reset}\n"
    printf "  ${color_green}(5)${color_reset} Horizon 5  ${color_gray}Purpose & Principles${color_reset}\n"
    printf "  ${color_green}(a)${color_reset} All        ${color_gray}Everything${color_reset}\n"
    printf "  ---\n"
    printf "  ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "

    if ! read this_choice; then
      this_organize_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      g|G) this_organize_choice="ground"   ; return 0 ;;
      1)   this_organize_choice="horizon1" ; return 0 ;;
      2)   this_organize_choice="horizon2" ; return 0 ;;
      3)   this_organize_choice="horizon3" ; return 0 ;;
      4)   this_organize_choice="horizon4" ; return 0 ;;
      5)   this_organize_choice="horizon5" ; return 0 ;;
      a|A) this_organize_choice="all"      ; return 0 ;;
      q|Q) this_organize_choice="quit"     ; return 0 ;;
      *)   ;; # invalid - redraw
    esac
  done
}

###########
# Helpers #
###########

# Args: <render_fn> <label>
# Clears the screen, runs the render function that already exists, then waits
# for ENTER to return to the menu. EOF propagates "quit" to the outer loop.
function organize_show_level() {
  local this_fn="$1"
  local this_label="$2"
  local _

  clear
  "${this_fn}"
  printf "\n${color_gray}Press ENTER to return to menu (or Ctrl+D to quit)...${color_reset}\n"
  if ! read _; then
    this_organize_choice="quit"
    return 0
  fi
}

function organize_show_all() {
  local _

  clear
  organize_ground
  organize_horizon1
  organize_horizon2
  organize_horizon3
  organize_horizon4
  organize_horizon5
  printf "\n${color_gray}Press ENTER to return to menu (or Ctrl+D to quit)...${color_reset}\n"
  if ! read _; then
    this_organize_choice="quit"
    return 0
  fi
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
