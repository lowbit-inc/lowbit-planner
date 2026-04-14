#!/bin/bash

function clarify_main() {

  log_print debug "Starting Clarify workflow"

  # Get all inbox item IDs
  this_inbox_ids=$(sqlite3 "${database_path}" "SELECT id FROM inbox ORDER BY id ASC;")

  if [[ -z "${this_inbox_ids}" ]]; then
    log_print info "Inbox is empty. Nothing to clarify."
    return
  fi

  # Count items
  this_inbox_count=$(echo "${this_inbox_ids}" | wc -l | tr -d ' ')
  log_print info "Found ${color_green}${this_inbox_count}${color_reset} item(s) in inbox"
  printf "\n"

  # Loop through each item
  this_item_number=0
  IFS=$'\n'
  for this_inbox_id in ${this_inbox_ids}; do
    this_item_number=$((this_item_number + 1))
    this_inbox_name=$(sqlite3 "${database_path}" "SELECT name FROM inbox WHERE id = ${this_inbox_id};")

    printf "${color_bold}[${this_item_number}/${this_inbox_count}]${color_reset} ${color_green}${this_inbox_name}${color_reset}\n"
    printf "\n"
    printf "  What type of object?\n"
    printf "  (t) Task       (r) Recurring   (h) Habit\n"
    printf "  (p) Project    (a) Area        (g) Goal\n"
    printf "  (v) Vision     (u) Purpose     (n) Principle\n"
    printf "  (c) Collection (i) Item\n"
    printf "  ---\n"
    printf "  (s) Skip       (d) Delete      (q) Quit\n"
    printf "\n"

    read -p "  > " this_choice

    case "${this_choice}" in
      "t")
        clarify_as_task "${this_inbox_id}" "${this_inbox_name}"
        ;;
      "r")
        clarify_as_recurring "${this_inbox_id}" "${this_inbox_name}"
        ;;
      "h")
        clarify_as_habit "${this_inbox_id}" "${this_inbox_name}"
        ;;
      "p")
        clarify_as_project "${this_inbox_id}" "${this_inbox_name}"
        ;;
      "a")
        clarify_as_area "${this_inbox_id}" "${this_inbox_name}"
        ;;
      "g")
        clarify_as_goal "${this_inbox_id}" "${this_inbox_name}"
        ;;
      "v")
        clarify_as_vision "${this_inbox_id}" "${this_inbox_name}"
        ;;
      "u")
        clarify_as_purpose "${this_inbox_id}" "${this_inbox_name}"
        ;;
      "n")
        clarify_as_principle "${this_inbox_id}" "${this_inbox_name}"
        ;;
      "c")
        clarify_as_collection "${this_inbox_id}" "${this_inbox_name}"
        ;;
      "i")
        clarify_as_item "${this_inbox_id}" "${this_inbox_name}"
        ;;
      "s")
        log_print info "Skipped '${this_inbox_name}'"
        printf "\n"
        continue
        ;;
      "d")
        database_run box "DELETE FROM inbox WHERE id = ${this_inbox_id};"
        log_print info "Deleted '${this_inbox_name}' from inbox"
        printf "\n"
        continue
        ;;
      "q")
        log_print info "Clarify session ended"
        return
        ;;
      *)
        log_print warn "Invalid choice. Skipping."
        printf "\n"
        continue
        ;;
    esac

    printf "\n"
  done
  unset IFS

  log_print info "Clarify session complete. All items processed."

}

function clarify_prompt_name() {
  local default_name="${1}"
  read -p "  Name [${default_name}]: " this_new_name
  if [[ -z "${this_new_name}" ]]; then
    echo "${default_name}"
  else
    echo "${this_new_name}"
  fi
}

function clarify_remove_from_inbox() {
  local this_id="${1}"
  database_run box "DELETE FROM inbox WHERE id = ${this_id};" >/dev/null 2>&1
}

function clarify_as_task() {
  local this_inbox_id="${1}"
  local this_inbox_name="${2}"

  local this_name=$(clarify_prompt_name "${this_inbox_name}")

  read -p "  Project (optional): " this_project
  read -p "  Start date YYYY-MM-DD (optional): " this_start_date
  read -p "  Due date YYYY-MM-DD (optional): " this_due_date

  local this_args=("${this_name}")
  [[ -n "${this_project}" ]] && this_args+=("--project" "${this_project}")
  [[ -n "${this_start_date}" ]] && this_args+=("--start-date" "${this_start_date}")
  [[ -n "${this_due_date}" ]] && this_args+=("--due-date" "${this_due_date}")

  task_add "${this_args[@]}"
  clarify_remove_from_inbox "${this_inbox_id}"
}

function clarify_as_recurring() {
  local this_inbox_id="${1}"
  local this_inbox_name="${2}"

  local this_name=$(clarify_prompt_name "${this_inbox_name}")

  read -p "  Recurrence (daily/weekly/monthly/quarterly/biannual/yearly): " this_recurrence

  if [[ -z "${this_recurrence}" ]]; then
    log_print warn "Recurrence is required. Skipping."
    return
  fi

  recurring_add "${this_name}" --recurrence "${this_recurrence}"
  clarify_remove_from_inbox "${this_inbox_id}"
}

function clarify_as_habit() {
  local this_inbox_id="${1}"
  local this_inbox_name="${2}"

  local this_name=$(clarify_prompt_name "${this_inbox_name}")

  read -p "  Recurrence (daily/weekly/monthly/quarterly/biannual/yearly): " this_recurrence

  if [[ -z "${this_recurrence}" ]]; then
    log_print warn "Recurrence is required. Skipping."
    return
  fi

  habit_add "${this_name}" --recurrence "${this_recurrence}"
  clarify_remove_from_inbox "${this_inbox_id}"
}

function clarify_as_project() {
  local this_inbox_id="${1}"
  local this_inbox_name="${2}"

  local this_name=$(clarify_prompt_name "${this_inbox_name}")

  read -p "  Area (required): " this_area
  if [[ -z "${this_area}" ]]; then
    log_print warn "Area is required. Skipping."
    return
  fi

  read -p "  Goal (optional): " this_goal
  read -p "  Start date YYYY-MM-DD (optional): " this_start_date
  read -p "  Due date YYYY-MM-DD (optional): " this_due_date

  local this_args=("${this_name}" "--area" "${this_area}")
  [[ -n "${this_goal}" ]] && this_args+=("--goal" "${this_goal}")
  [[ -n "${this_start_date}" ]] && this_args+=("--start-date" "${this_start_date}")
  [[ -n "${this_due_date}" ]] && this_args+=("--due-date" "${this_due_date}")

  project_add "${this_args[@]}"
  clarify_remove_from_inbox "${this_inbox_id}"
}

function clarify_as_area() {
  local this_inbox_id="${1}"
  local this_inbox_name="${2}"

  local this_name=$(clarify_prompt_name "${this_inbox_name}")

  read -p "  Description (optional): " this_description

  local this_args=("${this_name}")
  [[ -n "${this_description}" ]] && this_args+=("--description" "${this_description}")

  area_add "${this_args[@]}"
  clarify_remove_from_inbox "${this_inbox_id}"
}

function clarify_as_goal() {
  local this_inbox_id="${1}"
  local this_inbox_name="${2}"

  local this_name=$(clarify_prompt_name "${this_inbox_name}")

  read -p "  Area (required): " this_area
  if [[ -z "${this_area}" ]]; then
    log_print warn "Area is required. Skipping."
    return
  fi

  read -p "  Vision (optional): " this_vision
  read -p "  Start date YYYY-MM-DD (optional): " this_start_date
  read -p "  Due date YYYY-MM-DD (optional): " this_due_date

  local this_args=("${this_name}" "--area" "${this_area}")
  [[ -n "${this_vision}" ]] && this_args+=("--vision" "${this_vision}")
  [[ -n "${this_start_date}" ]] && this_args+=("--start-date" "${this_start_date}")
  [[ -n "${this_due_date}" ]] && this_args+=("--due-date" "${this_due_date}")

  goal_add "${this_args[@]}"
  clarify_remove_from_inbox "${this_inbox_id}"
}

function clarify_as_vision() {
  local this_inbox_id="${1}"
  local this_inbox_name="${2}"

  local this_name=$(clarify_prompt_name "${this_inbox_name}")

  read -p "  Area (required): " this_area
  if [[ -z "${this_area}" ]]; then
    log_print warn "Area is required. Skipping."
    return
  fi

  read -p "  Description (optional): " this_description
  read -p "  Start date YYYY-MM-DD (optional): " this_start_date
  read -p "  Due date YYYY-MM-DD (optional): " this_due_date

  local this_args=("${this_name}" "--area" "${this_area}")
  [[ -n "${this_description}" ]] && this_args+=("--description" "${this_description}")
  [[ -n "${this_start_date}" ]] && this_args+=("--start-date" "${this_start_date}")
  [[ -n "${this_due_date}" ]] && this_args+=("--due-date" "${this_due_date}")

  vision_add "${this_args[@]}"
  clarify_remove_from_inbox "${this_inbox_id}"
}

function clarify_as_purpose() {
  local this_inbox_id="${1}"
  local this_inbox_name="${2}"

  local this_name=$(clarify_prompt_name "${this_inbox_name}")

  purpose_add "${this_name}"
  clarify_remove_from_inbox "${this_inbox_id}"
}

function clarify_as_principle() {
  local this_inbox_id="${1}"
  local this_inbox_name="${2}"

  local this_name=$(clarify_prompt_name "${this_inbox_name}")

  principle_add "${this_name}"
  clarify_remove_from_inbox "${this_inbox_id}"
}

function clarify_as_collection() {
  local this_inbox_id="${1}"
  local this_inbox_name="${2}"

  local this_name=$(clarify_prompt_name "${this_inbox_name}")

  collection_add "${this_name}"
  clarify_remove_from_inbox "${this_inbox_id}"
}

function clarify_as_item() {
  local this_inbox_id="${1}"
  local this_inbox_name="${2}"

  local this_name=$(clarify_prompt_name "${this_inbox_name}")

  read -p "  Collection (required): " this_collection
  if [[ -z "${this_collection}" ]]; then
    log_print warn "Collection is required. Skipping."
    return
  fi

  item_add "${this_name}" --collection "${this_collection}"
  clarify_remove_from_inbox "${this_inbox_id}"
}
