#!/bin/bash

function reflect_main() {

  log_print debug "Starting Reflect workflow"

  # Review schedule:
  # Ground   - Daily   (inbox, tasks, recurring, habits, collections, items)
  # Horizon 1 - Weekly  (projects)
  # Horizon 2 - Monthly (areas)
  # Horizon 3 - Quarterly (goals)
  # Horizon 4 - Biannual (visions)
  # Horizon 5 - Yearly  (purposes, principles)

  if [[ ! "${1}" ]]; then
    # No args: show review status dashboard
    printf "${color_bold}${system_long_name} - Reflect${color_reset}\n"
    printf "\n"

    reflect_show_status "ground"   "Ground (Daily)"       "$(datetime_get_current_day)"
    reflect_show_status "horizon1" "Horizon 1 (Weekly)"   "$(datetime_get_current_week)"
    reflect_show_status "horizon2" "Horizon 2 (Monthly)"  "$(datetime_get_current_month)"
    reflect_show_status "horizon3" "Horizon 3 (Quarterly)" "$(datetime_get_current_quarter)"
    reflect_show_status "horizon4" "Horizon 4 (Biannual)" "$(datetime_get_current_semester)"
    reflect_show_status "horizon5" "Horizon 5 (Yearly)"   "$(datetime_get_current_year)"

    printf "\n"
    printf "  Run ${color_bold}${system_basename} reflect <horizon>${color_reset} to start a review.\n"
    printf "  Horizons: ${color_green}ground${color_reset}, ${color_green}horizon1${color_reset} (h1), ${color_green}horizon2${color_reset} (h2), ${color_green}horizon3${color_reset} (h3), ${color_green}horizon4${color_reset} (h4), ${color_green}horizon5${color_reset} (h5)\n"
    printf "\n"
    return
  fi

  this_level="${1}"

  case "${this_level}" in
    "ground")
      reflect_run_review "ground" "Ground"
      ;;
    "horizon1"|"h1")
      reflect_run_review "horizon1" "Horizon 1 - Projects"
      ;;
    "horizon2"|"h2")
      reflect_run_review "horizon2" "Horizon 2 - Areas"
      ;;
    "horizon3"|"h3")
      reflect_run_review "horizon3" "Horizon 3 - Goals"
      ;;
    "horizon4"|"h4")
      reflect_run_review "horizon4" "Horizon 4 - Visions"
      ;;
    "horizon5"|"h5")
      reflect_run_review "horizon5" "Horizon 5 - Purpose & Principles"
      ;;
    *)
      log_print warn "Unknown horizon '${this_level}'"
      printf "  Valid horizons: ground, horizon1 (h1), horizon2 (h2), horizon3 (h3), horizon4 (h4), horizon5 (h5)\n"
      ;;
  esac
}

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

function reflect_run_review() {
  local this_horizon="${1}"
  local this_label="${2}"

  printf "${color_bold}${color_bright_blue}═══ Reviewing: ${this_label} ═══${color_reset}\n"
  printf "\n"

  case "${this_horizon}" in
    "ground")
      reflect_review_ground
      ;;
    "horizon1")
      reflect_review_horizon1
      ;;
    "horizon2")
      reflect_review_horizon2
      ;;
    "horizon3")
      reflect_review_horizon3
      ;;
    "horizon4")
      reflect_review_horizon4
      ;;
    "horizon5")
      reflect_review_horizon5
      ;;
  esac

  # Mark review as done
  database_run box "UPDATE reviews SET last_reviewed_at = datetime('now') WHERE horizon = '${this_horizon}';"
  printf "${color_green}Review of ${this_label} marked as complete.${color_reset}\n"
  printf "\n"
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
