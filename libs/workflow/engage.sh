#!/bin/bash

##############
# Properties #
##############

# Communication between TUI layers (set by callees, read by callers):
#   this_engage_choice - "item:<N>" | "refresh" | "quit" | ""
#
# Dashboard item registry (built fresh at each dashboard redraw):
#   engage_item_types  - parallel array, 1..N: "task" | "recurring" | "habit" | "item"
#   engage_item_ids    - parallel array, 1..N: numeric ID from the backing table
#   engage_item_names  - parallel array, 1..N: display name (for confirmation prompts)
#   engage_item_count  - integer, number of items currently registered
#   engage_last_idx    - index most recently assigned by engage_append_item

###########
# Layer 1 #
# Session loop
###########

function engage_main() {
  log_print debug "Starting Engage workflow"

  while true; do
    this_engage_choice=""
    engage_screen_dashboard
    case "${this_engage_choice}" in
      quit|"")  return 0 ;;
      refresh)  continue ;;
      item:*)
        local this_idx="${this_engage_choice#item:}"
        engage_screen_item "${this_idx}"
        ;;
    esac
    # If a sub-screen got EOF, propagate quit out of the outer loop
    if [[ "${this_engage_choice}" == "quit" ]]; then
      return 0
    fi
  done
}

############
# Layer 2a #
# Dashboard TUI
############

function engage_screen_dashboard() {
  local this_choice
  engage_load_items

  local this_today=$(datetime_get_current_day)
  local this_3days=$(date -j -v+3d '+%Y-%m-%d')

  while true; do
    clear
    printf "${color_bold}${system_long_name} - Engage${color_reset}\n\n"

    engage_print_section_tasks "Overdue"   "${color_red}"    "due_date < '${this_today}' AND due_date != ''"
    engage_print_section_tasks "Due Today" "${color_yellow}" "due_date = '${this_today}'"

    if engage_has_tasks "due_date > '${this_today}' AND due_date <= '${this_3days}'"; then
      engage_print_section_tasks "Due in 3 Days" "${color_cyan}" "due_date > '${this_today}' AND due_date <= '${this_3days}'"
    else
      engage_print_section_next_available "${color_green}" "${this_today}"
    fi

    engage_print_section_one "Recurring"       "${color_magenta}"     "recurrings"       "ORDER BY id"
    engage_print_section_one "Habit"           "${color_blue}"        "habits"           "ORDER BY id"
    engage_print_section_one "Collection Item" "${color_bright_cyan}" "collection_items" "ORDER BY ci.position DESC, ci.name ASC"

    if [[ ${engage_item_count} -eq 0 ]]; then
      printf "  ${color_gray}Nothing actionable right now. Enjoy your free time!${color_reset}\n\n"
    fi

    printf "  ---\n"
    printf "  Enter item ${color_green}number${color_reset} to act, or ${color_green}(r)${color_reset}efresh, ${color_yellow}(q)${color_reset}uit\n\n"
    printf "> "

    if ! read this_choice; then
      this_engage_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      r|R) this_engage_choice="refresh" ; return 0 ;;
      q|Q) this_engage_choice="quit"    ; return 0 ;;
      '')  ;; # enter alone = redraw
      *)
        if [[ "${this_choice}" =~ ^[0-9]+$ ]] \
          && [[ "${this_choice}" -ge 1 ]] \
          && [[ "${this_choice}" -le ${engage_item_count} ]]; then
          this_engage_choice="item:${this_choice}"
          return 0
        fi
        ;; # invalid - redraw
    esac
  done
}

############
# Layer 2b #
# Item action submenu
############

# Args: <index>
function engage_screen_item() {
  local this_idx="$1"
  local this_type="${engage_item_types[${this_idx}]}"
  local this_id="${engage_item_ids[${this_idx}]}"
  local this_name="${engage_item_names[${this_idx}]}"
  local this_choice

  while true; do
    clear
    printf "${color_bold}${color_bright_blue}═══ ${this_type}: ${this_name} ═══${color_reset}\n\n"
    if engage_type_supports_start "${this_type}"; then
      printf "  ${color_green}(s)${color_reset} Start\n"
      printf "  ${color_green}(t)${color_reset} Stop\n"
    fi
    printf "  ${color_green}(c)${color_reset} Complete\n"
    printf "  ${color_green}(d)${color_reset} Delete\n"
    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back to dashboard\n"
    printf "  ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "

    if ! read this_choice; then
      this_engage_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      s|S)
        if engage_type_supports_start "${this_type}"; then
          engage_run_action "${this_type}" "start" "${this_id}"
          return 0
        fi
        ;;
      t|T)
        if engage_type_supports_start "${this_type}"; then
          engage_run_action "${this_type}" "stop" "${this_id}"
          return 0
        fi
        ;;
      c|C) engage_run_action "${this_type}" "complete" "${this_id}" ; return 0 ;;
      d|D) engage_run_action "${this_type}" "delete"   "${this_id}" ; return 0 ;;
      b|B) return 0 ;;
      q|Q) this_engage_choice="quit" ; return 0 ;;
      *)   ;; # invalid - redraw
    esac
  done
}

###########
# Helpers #
###########

# Reset the item registry. Called at the start of each dashboard redraw so
# numbering is fresh and reflects the current DB state.
function engage_load_items() {
  engage_item_types=()
  engage_item_ids=()
  engage_item_names=()
  engage_item_count=0
}

# Append an item to the registry and publish its assigned 1-based index via
# the global `engage_last_idx`. We use a side-effect global (not a subshell
# `$(...)` return) because bash command substitution forks a subshell, which
# would silently drop all updates to the parallel arrays and counter.
# Args: <type> <id> <name>
function engage_append_item() {
  ((engage_item_count++))
  engage_item_types[${engage_item_count}]="$1"
  engage_item_ids[${engage_item_count}]="$2"
  engage_item_names[${engage_item_count}]="$3"
  engage_last_idx=${engage_item_count}
}

# Return 0 (true) if the given item type supports start/stop.
# Args: <type>
function engage_type_supports_start() {
  case "$1" in
    task|item) return 0 ;;
    *)         return 1 ;;
  esac
}

# Dispatch to the backend <type>_<action> function using the item's ID, then
# pause so the user can read the resulting output before the dashboard redraws.
# "item" maps to the backend "item_*" functions (collection items).
# Args: <type> <action> <id>
function engage_run_action() {
  local this_type="$1"
  local this_action="$2"
  local this_id="$3"
  local _

  "${this_type}_${this_action}" "${this_id}"
  printf "\n${color_gray}Press ENTER to return to dashboard...${color_reset}\n"
  if ! read _; then
    this_engage_choice="quit"
    return 0
  fi
}

# Return 0 (true) if at least one task matches the given WHERE fragment (which
# must already combine with 'AND status != ''Done''').
# Args: <where_fragment>
function engage_has_tasks() {
  local this_count=$(database_run csv "SELECT COUNT(*) FROM tasks_view WHERE $1 AND status != 'Done';")
  [[ "${this_count}" -gt 0 ]]
}

# Print a tasks section. Shows up to 5 items; if more match, appends "(+N more)".
# Hides the section entirely when no rows match.
# Args: <label> <color> <where_fragment>
function engage_print_section_tasks() {
  local this_label="$1"
  local this_color="$2"
  local this_where="$3"

  local this_rows=$(database_run csv "SELECT id, name, project, due_date FROM tasks_view WHERE ${this_where} AND status != 'Done' LIMIT 6;")
  if [[ -z "${this_rows}" ]]; then
    return 0
  fi

  printf "${color_bold}${this_color}── ${this_label} ──${color_reset}\n"
  local this_count=0
  local id name project due_date
  while IFS=',' read -r id name project due_date; do
    [[ -z "${id}" ]] && continue
    if [[ ${this_count} -ge 5 ]]; then
      local this_total=$(database_run csv "SELECT COUNT(*) FROM tasks_view WHERE ${this_where} AND status != 'Done';")
      printf "      ${color_gray}(+$((this_total - 5)) more)${color_reset}\n"
      break
    fi
    local this_clean_name=$(echo "${name}" | tr -d '"')
    local this_clean_project=$(echo "${project}" | tr -d '"')
    local this_clean_due=$(echo "${due_date}" | tr -d '"')
    engage_append_item "task" "${id}" "${this_clean_name}"
    local this_idx=${engage_last_idx}
    local this_meta=""
    [[ -n "${this_clean_project}" ]] && this_meta+="project: ${this_clean_project}"
    [[ -n "${this_clean_due}" ]] && { [[ -n "${this_meta}" ]] && this_meta+=", "; this_meta+="due ${this_clean_due}"; }
    if [[ -n "${this_meta}" ]]; then
      printf "  ${color_green}%2d.${color_reset} %-36s ${color_gray}(%s)${color_reset}\n" "${this_idx}" "${this_clean_name}" "${this_meta}"
    else
      printf "  ${color_green}%2d.${color_reset} %s\n" "${this_idx}" "${this_clean_name}"
    fi
    ((this_count++))
  done <<< "${this_rows}"
  printf "\n"
}

# Print the "Next Available" fallback: 1 task with no due date and a start date
# that is empty or already past. Hides the section if no such task exists.
# Args: <color> <today>
function engage_print_section_next_available() {
  local this_color="$1"
  local this_today="$2"

  local this_row=$(database_run csv "SELECT id, name, project FROM tasks_view WHERE (due_date IS NULL OR due_date = '') AND (start_date IS NULL OR start_date = '' OR start_date <= '${this_today}') AND status != 'Done' LIMIT 1;")
  if [[ -z "${this_row}" ]]; then
    return 0
  fi

  printf "${color_bold}${this_color}── Next Available ──${color_reset}\n"
  local id name project
  IFS=',' read -r id name project <<< "${this_row}"
  local this_clean_name=$(echo "${name}" | tr -d '"')
  local this_clean_project=$(echo "${project}" | tr -d '"')
  engage_append_item "task" "${id}" "${this_clean_name}"
  local this_idx=${engage_last_idx}
  if [[ -n "${this_clean_project}" ]]; then
    printf "  ${color_green}%2d.${color_reset} %-36s ${color_gray}(project: %s)${color_reset}\n" "${this_idx}" "${this_clean_name}" "${this_clean_project}"
  else
    printf "  ${color_green}%2d.${color_reset} %s\n" "${this_idx}" "${this_clean_name}"
  fi
  printf "\n"
}

# Print one pending item from a single-object table (recurrings/habits/collection_items).
# Hides the section if no pending row exists.
# Args: <label> <color> <table> <order_by>
function engage_print_section_one() {
  local this_label="$1"
  local this_color="$2"
  local this_table="$3"
  local this_order="$4"

  local this_row
  local this_type
  case "${this_table}" in
    recurrings)
      this_row=$(database_run csv "SELECT id, name, recurrence FROM recurrings WHERE status = 'Pending' ${this_order} LIMIT 1;")
      this_type="recurring"
      ;;
    habits)
      this_row=$(database_run csv "SELECT id, name, recurrence FROM habits WHERE status = 'Pending' ${this_order} LIMIT 1;")
      this_type="habit"
      ;;
    collection_items)
      this_row=$(database_run csv "SELECT ci.id, ci.name, c.name FROM collection_items ci LEFT JOIN collections c ON ci.collection_id = c.id WHERE ci.status = 'Pending' ${this_order} LIMIT 1;")
      this_type="item"
      ;;
  esac

  if [[ -z "${this_row}" ]]; then
    return 0
  fi

  printf "${color_bold}${this_color}── ${this_label} ──${color_reset}\n"
  local id name extra
  IFS=',' read -r id name extra <<< "${this_row}"
  local this_clean_name=$(echo "${name}" | tr -d '"')
  local this_clean_extra=$(echo "${extra}" | tr -d '"')
  engage_append_item "${this_type}" "${id}" "${this_clean_name}"
  local this_idx=${engage_last_idx}
  local this_meta
  case "${this_table}" in
    recurrings|habits) this_meta="${this_clean_extra}" ;;
    collection_items)  this_meta="from: ${this_clean_extra}" ;;
  esac
  if [[ -n "${this_clean_extra}" ]]; then
    printf "  ${color_green}%2d.${color_reset} %-36s ${color_gray}(%s)${color_reset}\n" "${this_idx}" "${this_clean_name}" "${this_meta}"
  else
    printf "  ${color_green}%2d.${color_reset} %s\n" "${this_idx}" "${this_clean_name}"
  fi
  printf "\n"
}
