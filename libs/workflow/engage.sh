#!/bin/bash

function engage_main() {

  log_print debug "Starting Engage workflow"

  printf "${color_bold}${system_long_name} - Engage${color_reset}\n"
  printf "${color_gray}What to work on now:${color_reset}\n"
  printf "\n"

  local this_today=$(datetime_get_current_day)
  local this_3days=$(date -j -v+3d '+%Y-%m-%d')
  local this_found=false

  # 1. Overdue tasks (due_date < today, not done)
  local this_overdue=$(database_run box "SELECT * FROM tasks_view WHERE due_date < '${this_today}' AND due_date != '' AND status != 'Done';")
  if [[ -n "${this_overdue}" ]]; then
    printf "${color_bold}${color_red}Overdue Tasks${color_reset}\n"
    echo "${this_overdue}"
    printf "\n"
    this_found=true
  fi

  # 2. Tasks due today
  local this_due_today=$(database_run box "SELECT * FROM tasks_view WHERE due_date = '${this_today}' AND status != 'Done';")
  if [[ -n "${this_due_today}" ]]; then
    printf "${color_bold}${color_yellow}Due Today${color_reset}\n"
    echo "${this_due_today}"
    printf "\n"
    this_found=true
  fi

  # 3. Tasks due in 3 days
  local this_due_soon=$(database_run box "SELECT * FROM tasks_view WHERE due_date > '${this_today}' AND due_date <= '${this_3days}' AND status != 'Done';")
  if [[ -n "${this_due_soon}" ]]; then
    printf "${color_bold}${color_cyan}Due in 3 Days${color_reset}\n"
    echo "${this_due_soon}"
    printf "\n"
    this_found=true
  fi

  # 4. Next task without deadline (start_date empty or <= today, no due_date, not done, LIMIT 1)
  local this_next_task=$(database_run box "SELECT * FROM tasks_view WHERE (due_date IS NULL OR due_date = '') AND (start_date IS NULL OR start_date = '' OR start_date <= '${this_today}') AND status != 'Done' LIMIT 1;")
  if [[ -n "${this_next_task}" ]]; then
    printf "${color_bold}${color_green}Next Task${color_reset}\n"
    echo "${this_next_task}"
    printf "\n"
    this_found=true
  fi

  # 5. Next pending recurring (LIMIT 1)
  local this_next_recurring=$(database_run box "SELECT * FROM recurrings_view WHERE status = 'Pending' LIMIT 1;")
  if [[ -n "${this_next_recurring}" ]]; then
    printf "${color_bold}${color_magenta}Pending Recurring${color_reset}\n"
    echo "${this_next_recurring}"
    printf "\n"
    this_found=true
  fi

  # 6. Next pending habit (LIMIT 1)
  local this_next_habit=$(database_run box "SELECT * FROM habits_view WHERE status = 'Pending' LIMIT 1;")
  if [[ -n "${this_next_habit}" ]]; then
    printf "${color_bold}${color_blue}Pending Habit${color_reset}\n"
    echo "${this_next_habit}"
    printf "\n"
    this_found=true
  fi

  # 7. Random pending collection item (random collection, highest position, LIMIT 1)
  local this_next_item=$(database_run box "SELECT ci.id, ci.name, c.name AS collection, ci.position, ci.ranking, ci.status FROM collection_items ci LEFT JOIN collections c ON ci.collection_id = c.id WHERE ci.status = 'Pending' ORDER BY RANDOM() LIMIT 1;")
  if [[ -n "${this_next_item}" ]]; then
    printf "${color_bold}${color_bright_cyan}Collection Item${color_reset}\n"
    echo "${this_next_item}"
    printf "\n"
    this_found=true
  fi

  if [[ "${this_found}" == "false" ]]; then
    printf "  ${color_green}Nothing actionable right now. Enjoy your free time!${color_reset}\n"
    printf "\n"
  fi
}
