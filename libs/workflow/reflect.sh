#!/bin/bash

##############
# Properties #
##############

# Communication between TUI layers (set by callees, read by callers):
#   this_reflect_choice - "ground" | "horizon1"..."horizon5" | "quit" | ""

# Review schedule:
#   Ground    - Daily     (inbox, tasks, recurring, habits, collections, items)
#   Horizon 1 - Weekly    (projects)
#   Horizon 2 - Monthly   (areas)
#   Horizon 3 - Quarterly (goals)
#   Horizon 4 - Biannual  (visions)
#   Horizon 5 - Yearly    (purposes, principles)

###########
# Layer 1 #
# Main loop
###########

function reflect_main() {
  log_print debug "Starting Reflect workflow"

  while true; do
    this_reflect_choice=""
    reflect_screen_menu
    case "${this_reflect_choice}" in
      quit|"")  return 0 ;;
      ground)    reflect_screen_horizon "ground"   "Ground"                           ;;
      horizon1)  reflect_screen_horizon "horizon1" "Horizon 1 - Projects"             ;;
      horizon2)  reflect_screen_horizon "horizon2" "Horizon 2 - Areas"                ;;
      horizon3)  reflect_screen_horizon "horizon3" "Horizon 3 - Goals"                ;;
      horizon4)  reflect_screen_horizon "horizon4" "Horizon 4 - Visions"              ;;
      horizon5)  reflect_screen_horizon "horizon5" "Horizon 5 - Purpose & Principles" ;;
    esac
    # If a nested screen got EOF, propagate quit out of the outer loop
    if [[ "${this_reflect_choice}" == "quit" ]]; then
      return 0
    fi
  done
}

############
# Layer 2a #
# Main menu TUI (with inline status)
############

function reflect_screen_menu() {
  local this_choice
  while true; do
    clear
    printf "${color_bold}${system_long_name} - Reflect${color_reset}\n\n"
    printf "  Choose a horizon to review:\n\n"
    reflect_print_menu_item "g" "ground"   "Ground (Daily)"        "$(datetime_get_current_day)"
    reflect_print_menu_item "1" "horizon1" "Horizon 1 (Weekly)"    "$(datetime_get_current_week)"
    reflect_print_menu_item "2" "horizon2" "Horizon 2 (Monthly)"   "$(datetime_get_current_month)"
    reflect_print_menu_item "3" "horizon3" "Horizon 3 (Quarterly)" "$(datetime_get_current_quarter)"
    reflect_print_menu_item "4" "horizon4" "Horizon 4 (Biannual)"  "$(datetime_get_current_semester)"
    reflect_print_menu_item "5" "horizon5" "Horizon 5 (Yearly)"    "$(datetime_get_current_year)"
    printf "  ---\n"
    printf "  ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "

    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      g|G) this_reflect_choice="ground"   ; return 0 ;;
      1)   this_reflect_choice="horizon1" ; return 0 ;;
      2)   this_reflect_choice="horizon2" ; return 0 ;;
      3)   this_reflect_choice="horizon3" ; return 0 ;;
      4)   this_reflect_choice="horizon4" ; return 0 ;;
      5)   this_reflect_choice="horizon5" ; return 0 ;;
      q|Q) this_reflect_choice="quit"     ; return 0 ;;
      *)   ;; # invalid - redraw
    esac
  done
}

# Args: <key> <horizon> <label> <current_period>
# Renders one line of the main menu with the review status badge inline.
function reflect_print_menu_item() {
  local this_key="$1"
  local this_horizon="$2"
  local this_label="$3"
  local this_current_period="$4"

  local this_last_reviewed=$(database_run csv "SELECT last_reviewed_at FROM reviews WHERE horizon = '${this_horizon}';" | tr -d '"')
  local this_badge
  local this_suffix

  if [[ -z "${this_last_reviewed}" ]]; then
    this_badge="${color_yellow}[!]${color_reset}"
    this_suffix="${color_yellow}Never reviewed${color_reset}"
  elif reflect_is_current "${this_horizon}" "${this_last_reviewed}" "${this_current_period}"; then
    this_badge="${color_green}[v]${color_reset}"
    this_suffix="Last: ${this_last_reviewed}"
  else
    this_badge="${color_yellow}[!]${color_reset}"
    this_suffix="${color_yellow}Due${color_reset} (last: ${this_last_reviewed})"
  fi

  printf "  ${color_green}(%s)${color_reset} %s ${color_bold}%s${color_reset} — %s\n" \
    "${this_key}" "${this_badge}" "${this_label}" "${this_suffix}"
}

############
# Layer 2b #
# Horizon review TUI
############

# Args: <horizon> <label>
function reflect_screen_horizon() {
  local this_horizon="$1"
  local this_label="$2"
  local this_choice

  while true; do
    clear
    printf "${color_bold}${color_bright_blue}═══ Reviewing: ${this_label} ═══${color_reset}\n\n"
    printf "  ${color_green}(l)${color_reset} List items\n"
    if reflect_horizon_has_decide "${this_horizon}"; then
      printf "  ${color_green}(d)${color_reset} Decide\n"
    fi
    printf "  ${color_green}(m)${color_reset} Mark review as complete\n"
    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back to main menu\n"
    printf "  ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "

    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      l|L)
        reflect_show_list "${this_horizon}"
        ;;
      d|D)
        if reflect_horizon_has_decide "${this_horizon}"; then
          reflect_run_decide "${this_horizon}"
        fi
        ;;
      m|M)
        reflect_mark_complete "${this_horizon}" "${this_label}"
        return 0
        ;;
      b|B)
        return 0
        ;;
      q|Q)
        this_reflect_choice="quit"
        return 0
        ;;
      *)
        ;; # invalid - redraw
    esac

    # If a sub-action propagated quit (via Ctrl+D in list/decide/mark), honor it
    if [[ "${this_reflect_choice}" == "quit" ]]; then
      return 0
    fi
  done
}

###########
# Helpers #
###########

# Returns 0 (true) if the horizon has a backend "decide" implementation.
# Args: <horizon>
function reflect_horizon_has_decide() {
  case "$1" in
    horizon1|horizon3|horizon4) return 0 ;;
    *)                          return 1 ;;
  esac
}

# Clear, render the horizon list via the existing render function, wait for ENTER.
# Args: <horizon>
function reflect_show_list() {
  local this_horizon="$1"
  local _

  clear
  case "${this_horizon}" in
    ground)   reflect_review_ground   ;;
    horizon1) reflect_review_horizon1 ;;
    horizon2) reflect_review_horizon2 ;;
    horizon3) reflect_review_horizon3 ;;
    horizon4) reflect_review_horizon4 ;;
    horizon5) reflect_review_horizon5 ;;
  esac
  printf "\n${color_gray}Press ENTER to return (or Ctrl+D to quit)...${color_reset}\n"
  if ! read _; then
    this_reflect_choice="quit"
    return 0
  fi
}

# Dispatch to the object-level decide function. Only called for horizons where
# reflect_horizon_has_decide returns true.
# Args: <horizon>
function reflect_run_decide() {
  local _

  case "$1" in
    horizon1) project_decide ;;
    horizon3) goal_decide    ;;
    horizon4) vision_decide  ;;
  esac
  printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
  if ! read _; then
    this_reflect_choice="quit"
    return 0
  fi
}

# Mark a horizon's review as complete (update reviews table), show confirmation,
# wait for ENTER, return. Caller should return after this so the main loop
# redraws the menu with the new [v] badge.
# Args: <horizon> <label>
function reflect_mark_complete() {
  local this_horizon="$1"
  local this_label="$2"
  local _

  database_run box "UPDATE reviews SET last_reviewed_at = datetime('now', 'localtime') WHERE horizon = '${this_horizon}';" >/dev/null
  clear
  printf "${color_green}Review of ${this_label} marked as complete.${color_reset}\n"
  printf "\n${color_gray}Press ENTER to return to main menu...${color_reset}\n"
  if ! read _; then
    this_reflect_choice="quit"
    return 0
  fi
}

#################
# Render helpers #
#################

# Kept from the pre-TUI implementation — still used by reflect_print_menu_item
# to compute the inline badge, and retained as a reusable helper.
function reflect_show_status() {
  local this_horizon="${1}"
  local this_label="${2}"
  local this_current_period="${3}"

  local this_last_reviewed=$(database_run csv "SELECT last_reviewed_at FROM reviews WHERE horizon = '${this_horizon}';" | tr -d '"')

  if [[ -z "${this_last_reviewed}" ]]; then
    printf "  ${color_yellow}[!]${color_reset} ${color_bold}${this_label}${color_reset} — ${color_yellow}Never reviewed${color_reset}\n"
  else
    # Check if the review is current
    if reflect_is_current "${this_horizon}" "${this_last_reviewed}" "${this_current_period}"; then
      printf "  ${color_green}[v]${color_reset} ${color_bold}${this_label}${color_reset} — Last: ${this_last_reviewed}\n"
    else
      printf "  ${color_yellow}[!]${color_reset} ${color_bold}${this_label}${color_reset} — ${color_yellow}Due${color_reset} (last: ${this_last_reviewed})\n"
    fi
  fi
}

function reflect_is_current() {
  local this_horizon="${1}"
  local this_last_reviewed="${2}"
  local this_current_period="${3}"

  # Extract date part from last_reviewed (may include time)
  local this_review_date=$(echo "${this_last_reviewed}" | cut -d' ' -f1)

  case "${this_horizon}" in
    "ground")
      local this_review_period="${this_review_date}"
      ;;
    "horizon1")
      local this_review_period=$(datetime_get_week_from_date "${this_review_date}")
      ;;
    "horizon2")
      local this_review_period=$(datetime_get_month_from_date "${this_review_date}")
      ;;
    "horizon3")
      local this_review_period=$(datetime_get_quarter_from_date "${this_review_date}")
      ;;
    "horizon4")
      local this_review_period=$(datetime_get_semester_from_date "${this_review_date}")
      ;;
    "horizon5")
      local this_review_period=$(datetime_get_year_from_date "${this_review_date}")
      ;;
  esac

  [[ "${this_review_period}" == "${this_current_period}" ]]
}

function reflect_review_ground() {
  # Show inbox
  printf "${color_bold}${color_cyan}── Inbox ──${color_reset}\n"
  local this_inbox=$(database_run box "SELECT * FROM inbox_view")
  if [[ -n "${this_inbox}" ]]; then
    echo "${this_inbox}"
    printf "\n"
    printf "  ${color_yellow}Tip: Run '${system_basename} clarify' to process inbox items.${color_reset}\n"
  else
    printf "  ${color_gray}(empty)${color_reset}\n"
  fi
  printf "\n"

  # Show active tasks
  printf "${color_bold}${color_cyan}── Active Tasks ──${color_reset}\n"
  local this_tasks=$(database_run box "SELECT * FROM tasks_view WHERE status != 'Done'")
  if [[ -n "${this_tasks}" ]]; then
    echo "${this_tasks}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"

  # Show pending recurring
  printf "${color_bold}${color_cyan}── Recurring (Pending) ──${color_reset}\n"
  local this_recurrings=$(database_run box "SELECT * FROM recurrings_view WHERE status = 'Pending'")
  if [[ -n "${this_recurrings}" ]]; then
    echo "${this_recurrings}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"

  # Show pending habits
  printf "${color_bold}${color_cyan}── Habits (Pending) ──${color_reset}\n"
  local this_habits=$(database_run box "SELECT * FROM habits_view WHERE status = 'Pending'")
  if [[ -n "${this_habits}" ]]; then
    echo "${this_habits}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
}

function reflect_review_horizon1() {
  printf "${color_bold}${color_cyan}── Active Projects ──${color_reset}\n"
  local this_projects=$(database_run box "SELECT * FROM projects_view WHERE status != 'Done'")
  if [[ -n "${this_projects}" ]]; then
    echo "${this_projects}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
  printf "  ${color_yellow}Tip: Do all projects have a next action? Any stalled?${color_reset}\n"
  printf "\n"
}

function reflect_review_horizon2() {
  printf "${color_bold}${color_cyan}── Areas of Responsibility ──${color_reset}\n"
  local this_areas=$(database_run box "SELECT * FROM areas_view")
  if [[ -n "${this_areas}" ]]; then
    echo "${this_areas}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
  printf "  ${color_yellow}Tip: Is each area being maintained? Any missing projects?${color_reset}\n"
  printf "\n"
}

function reflect_review_horizon3() {
  printf "${color_bold}${color_cyan}── Active Goals ──${color_reset}\n"
  local this_goals=$(database_run box "SELECT * FROM goals_view WHERE status != 'Done'")
  if [[ -n "${this_goals}" ]]; then
    echo "${this_goals}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
  printf "  ${color_yellow}Tip: Are goals on track? Any projects missing to achieve them?${color_reset}\n"
  printf "\n"
}

function reflect_review_horizon4() {
  printf "${color_bold}${color_cyan}── Active Visions ──${color_reset}\n"
  local this_visions=$(database_run box "SELECT * FROM visions_view WHERE status != 'Done'")
  if [[ -n "${this_visions}" ]]; then
    echo "${this_visions}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
  printf "  ${color_yellow}Tip: Do your visions still align with your purpose?${color_reset}\n"
  printf "\n"
}

function reflect_review_horizon5() {
  printf "${color_bold}${color_cyan}── Purposes ──${color_reset}\n"
  local this_purposes=$(database_run box "SELECT * FROM purposes_view")
  if [[ -n "${this_purposes}" ]]; then
    echo "${this_purposes}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"

  printf "${color_bold}${color_cyan}── Principles ──${color_reset}\n"
  local this_principles=$(database_run box "SELECT * FROM principles_view")
  if [[ -n "${this_principles}" ]]; then
    echo "${this_principles}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
  printf "\n"
  printf "  ${color_yellow}Tip: Does your life direction still resonate? Any new principles?${color_reset}\n"
  printf "\n"
}
