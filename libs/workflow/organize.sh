#!/bin/bash

##############
# Properties #
##############

# 3-level explorer:
#   L1 horizon menu  -> L2 object menu (ground, horizon5) OR direct to L3 (h1-h4)
#   L2 object menu   -> L3 operations menu for the selected type
#   L3 operations    -> invoke <type>_<verb> from libs/objects/*.sh
#
# Inter-layer comms:
#   this_organize_choice        - "quit" | "" (propagates EOF out to outer loops)
#   this_organize_picker_id     - numeric id chosen in organize_screen_id_picker
#   this_organize_picker_name   - label of the same row
#   this_form_result            - set by clarify_screen_object_form (reused as-is)

##########
# Layer 1
# Main loop
##########

function organize_main() {
  log_print debug "Starting Organize workflow"
  this_organize_choice=""
  organize_screen_horizon_menu
}

##########
# Layer 2a
# Horizon menu (root)
##########

function organize_screen_horizon_menu() {
  local this_choice
  while true; do
    clear
    workflow_print_header "organize"
    printf "  Choose a horizon:\n\n"
    printf "  ${color_green}(g)${color_reset} Ground     ${color_gray}Inbox, Tasks, Recurring, Habits, Collections, Items${color_reset}\n"
    printf "  ${color_green}(1)${color_reset} Horizon 1  ${color_gray}Projects${color_reset}\n"
    printf "  ${color_green}(2)${color_reset} Horizon 2  ${color_gray}Areas${color_reset}\n"
    printf "  ${color_green}(3)${color_reset} Horizon 3  ${color_gray}Goals${color_reset}\n"
    printf "  ${color_green}(4)${color_reset} Horizon 4  ${color_gray}Visions${color_reset}\n"
    printf "  ${color_green}(5)${color_reset} Horizon 5  ${color_gray}Purposes & Principles${color_reset}\n"
    printf "  ---\n"
    printf "  ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "

    if ! read this_choice; then
      return 0
    fi

    if workflow_try_switch "${this_choice}" "organize"; then
      return 0
    fi

    case "${this_choice}" in
      g|G) organize_screen_object_menu "ground"   ;;
      1)   organize_screen_object_ops  "project"  ;;
      2)   organize_screen_object_ops  "area"     ;;
      3)   organize_screen_object_ops  "goal"     ;;
      4)   organize_screen_object_ops  "vision"   ;;
      5)   organize_screen_object_menu "horizon5" ;;
      q|Q) return 0 ;;
      *)   ;; # invalid - redraw
    esac

    [[ "${this_organize_choice}" == "quit" ]] && return 0
  done
}

##########
# Layer 2b
# Object menu (ground / horizon5 only)
##########

# Args: <horizon>   horizon in {ground, horizon5}
function organize_screen_object_menu() {
  local this_horizon="$1"
  local this_choice
  while true; do
    clear
    workflow_print_header "organize"

    case "${this_horizon}" in
      ground)
        printf "${color_bold}${color_bright_blue}═══ Ground ═══${color_reset}\n\n"
        printf "  Choose an object type:\n\n"
        printf "  ${color_green}(i)${color_reset} Inbox\n"
        printf "  ${color_green}(t)${color_reset} Task\n"
        printf "  ${color_green}(r)${color_reset} Recurring\n"
        printf "  ${color_green}(h)${color_reset} Habit\n"
        printf "  ${color_green}(c)${color_reset} Collection\n"
        printf "  ${color_green}(x)${color_reset} Item\n"
        ;;
      horizon5)
        printf "${color_bold}${color_bright_blue}═══ Horizon 5 ═══${color_reset}\n\n"
        printf "  Choose an object type:\n\n"
        printf "  ${color_green}(u)${color_reset} Purpose\n"
        printf "  ${color_green}(n)${color_reset} Principle\n"
        ;;
    esac

    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "

    if ! read this_choice; then
      this_organize_choice="quit"
      return 0
    fi

    case "${this_horizon}" in
      ground)
        case "${this_choice}" in
          i|I) organize_screen_object_ops "inbox"      ;;
          t|T) organize_screen_object_ops "task"       ;;
          r|R) organize_screen_object_ops "recurring"  ;;
          h|H) organize_screen_object_ops "habit"      ;;
          c|C) organize_screen_object_ops "collection" ;;
          x|X) organize_screen_object_ops "item"       ;;
          b|B) return 0 ;;
          q|Q) this_organize_choice="quit" ; return 0 ;;
          *)   ;;
        esac
        ;;
      horizon5)
        case "${this_choice}" in
          u|U) organize_screen_object_ops "purpose"   ;;
          n|N) organize_screen_object_ops "principle" ;;
          b|B) return 0 ;;
          q|Q) this_organize_choice="quit" ; return 0 ;;
          *)   ;;
        esac
        ;;
    esac

    [[ "${this_organize_choice}" == "quit" ]] && return 0
  done
}

##########
# Layer 2c
# Capability table: which verbs each type supports.
##########

# Echoes a space-separated list of verbs supported by <type>.
# Verbs: list add complete start stop decide remove
function organize_type_caps() {
  case "$1" in
    inbox)      echo "list add remove" ;;
    task)       echo "list add complete start stop remove" ;;
    recurring)  echo "list add complete remove" ;;
    habit)      echo "list add complete remove" ;;
    collection) echo "list add decide remove" ;;
    item)       echo "list add complete start stop remove" ;;
    project)    echo "list add complete start stop decide remove" ;;
    area)       echo "list add remove" ;;
    goal)       echo "list add complete start stop decide remove" ;;
    vision)     echo "list add complete start stop decide remove" ;;
    purpose)    echo "list add remove" ;;
    principle)  echo "list add remove" ;;
  esac
}

function organize_caps_has() {
  local this_caps="$1"
  local this_verb="$2"
  [[ " ${this_caps} " == *" ${this_verb} "* ]]
}

##########
# Layer 3
# Operations menu for a given type
##########

# Args: <type>
function organize_screen_object_ops() {
  local this_type="$1"
  local this_caps=$(organize_type_caps "${this_type}")
  local this_title_type=$(organize_type_title "${this_type}")
  local this_choice

  while true; do
    clear
    workflow_print_header "organize"
    printf "${color_bold}${color_bright_blue}═══ ${this_title_type} ═══${color_reset}\n\n"

    organize_caps_has "${this_caps}" "list"     && printf "  ${color_green}(l)${color_reset} List\n"
    organize_caps_has "${this_caps}" "add"      && printf "  ${color_green}(a)${color_reset} Add\n"
    organize_caps_has "${this_caps}" "complete" && printf "  ${color_green}(c)${color_reset} Complete\n"
    organize_caps_has "${this_caps}" "start"    && printf "  ${color_green}(s)${color_reset} Start\n"
    organize_caps_has "${this_caps}" "stop"     && printf "  ${color_green}(x)${color_reset} Stop\n"
    organize_caps_has "${this_caps}" "decide"   && printf "  ${color_green}(d)${color_reset} Decide\n"
    organize_caps_has "${this_caps}" "remove"   && printf "  ${color_green}(r)${color_reset} Remove\n"
    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "

    if ! read this_choice; then
      this_organize_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      l|L) organize_caps_has "${this_caps}" "list"     && organize_action_list     "${this_type}" ;;
      a|A) organize_caps_has "${this_caps}" "add"      && organize_action_add      "${this_type}" ;;
      c|C) organize_caps_has "${this_caps}" "complete" && organize_action_complete "${this_type}" ;;
      s|S) organize_caps_has "${this_caps}" "start"    && organize_action_start    "${this_type}" ;;
      x|X) organize_caps_has "${this_caps}" "stop"     && organize_action_stop     "${this_type}" ;;
      d|D) organize_caps_has "${this_caps}" "decide"   && organize_action_decide   "${this_type}" ;;
      r|R) organize_caps_has "${this_caps}" "remove"   && organize_action_remove   "${this_type}" ;;
      b|B) return 0 ;;
      q|Q) this_organize_choice="quit" ; return 0 ;;
      *)   ;;
    esac

    [[ "${this_organize_choice}" == "quit" ]] && return 0
  done
}

# Args: <type>
function organize_type_title() {
  case "$1" in
    inbox)      echo "Inbox" ;;
    task)       echo "Task" ;;
    recurring)  echo "Recurring" ;;
    habit)      echo "Habit" ;;
    collection) echo "Collection" ;;
    item)       echo "Item" ;;
    project)    echo "Project" ;;
    area)       echo "Area" ;;
    goal)       echo "Goal" ;;
    vision)     echo "Vision" ;;
    purpose)    echo "Purpose" ;;
    principle)  echo "Principle" ;;
  esac
}

##########
# Helpers
##########

# Args: <title> <query>   query must SELECT id, label FROM ...
# Sets this_organize_picker_id / this_organize_picker_name on selection, leaves
# them empty on back. EOF / (q)uit propagates via this_organize_choice="quit".
function organize_screen_id_picker() {
  local this_title="$1"
  local this_query="$2"
  this_organize_picker_id=""
  this_organize_picker_name=""

  local this_choice
  local i
  while true; do
    clear
    workflow_print_header "organize"
    printf "${color_bold}${color_bright_blue}═══ ${this_title} ═══${color_reset}\n\n"

    local this_raw
    this_raw=$(sqlite3 -separator $'\t' "${database_path}" "${this_query}")

    local -a this_ids=()
    local -a this_names=()
    if [[ -n "${this_raw}" ]]; then
      local id label
      while IFS=$'\t' read -r id label; do
        this_ids+=("${id}")
        this_names+=("${label}")
      done <<< "${this_raw}"
    fi

    if [[ ${#this_ids[@]} -eq 0 ]]; then
      printf "  ${color_gray}(none)${color_reset}\n\n"
    else
      for i in "${!this_ids[@]}"; do
        printf "  ${color_green}(%d)${color_reset} %s\n" "$((i+1))" "${this_names[$i]}"
      done
      printf "\n"
    fi

    printf "  ---\n"
    printf "  Enter a ${color_green}number${color_reset}, or ${color_yellow}(b)${color_reset} Back / ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "

    if ! read this_choice; then
      this_organize_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      b|B) return 0 ;;
      q|Q) this_organize_choice="quit" ; return 0 ;;
      *[!0-9]*|"") ;;
      *)
        if (( this_choice >= 1 && this_choice <= ${#this_ids[@]} )); then
          this_organize_picker_id="${this_ids[$((this_choice-1))]}"
          this_organize_picker_name="${this_names[$((this_choice-1))]}"
          return 0
        fi
        ;;
    esac
  done
}

# Args: <type>  -> the view name and (optional) WHERE filter.
function organize_list_query() {
  case "$1" in
    inbox)      echo "SELECT id, name FROM inbox_view" ;;
    task)       echo "SELECT id, name FROM tasks_view WHERE status != 'Done'" ;;
    recurring)  echo "SELECT id, name FROM recurrings_view WHERE status != 'Done'" ;;
    habit)      echo "SELECT id, name FROM habits_view WHERE status != 'Done'" ;;
    collection) echo "SELECT id, name FROM collections_view" ;;
    item)       echo "SELECT id, name FROM collection_items_view WHERE status != 'Done'" ;;
    project)    echo "SELECT id, name FROM projects_view WHERE status != 'Done'" ;;
    area)       echo "SELECT id, name FROM areas_view" ;;
    goal)       echo "SELECT id, name FROM goals_view WHERE status != 'Done'" ;;
    vision)     echo "SELECT id, name FROM visions_view WHERE status != 'Done'" ;;
    purpose)    echo "SELECT id, name FROM purposes_view" ;;
    principle)  echo "SELECT id, name FROM principles_view" ;;
  esac
}

function organize_view_name() {
  case "$1" in
    inbox)      echo "inbox_view" ;;
    task)       echo "tasks_view" ;;
    recurring)  echo "recurrings_view" ;;
    habit)      echo "habits_view" ;;
    collection) echo "collections_view" ;;
    item)       echo "collection_items_view" ;;
    project)    echo "projects_view" ;;
    area)       echo "areas_view" ;;
    goal)       echo "goals_view" ;;
    vision)     echo "visions_view" ;;
    purpose)    echo "purposes_view" ;;
    principle)  echo "principles_view" ;;
  esac
}

##########
# Actions
##########

function organize_action_list() {
  local this_type="$1"
  local this_title=$(organize_type_title "${this_type}")
  local this_view=$(organize_view_name "${this_type}")
  local _

  clear
  workflow_print_header "organize"
  printf "${color_bold}${color_bright_blue}═══ ${this_title} ═══${color_reset}\n\n"

  local this_where=""
  case "${this_type}" in
    task|recurring|habit|item|project|goal|vision) this_where=" WHERE status != 'Done'" ;;
  esac
  local this_rows=$(database_run box "SELECT * FROM ${this_view}${this_where}")
  if [[ -n "${this_rows}" ]]; then
    echo "${this_rows}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi

  printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
  if ! read _; then
    this_organize_choice="quit"
    return 0
  fi
}

function organize_action_add() {
  local this_type="$1"
  local _

  if [[ "${this_type}" == "inbox" ]]; then
    clear
    workflow_print_header "organize"
    printf "${color_bold}${color_bright_blue}═══ Add to Inbox ═══${color_reset}\n\n"
    printf "  Name (empty to cancel): "
    local this_name
    if ! read this_name; then
      this_organize_choice="quit"
      return 0
    fi
    if [[ -n "${this_name}" ]]; then
      inbox_add "${this_name}"
      printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
      if ! read _; then
        this_organize_choice="quit"
        return 0
      fi
    fi
    return 0
  fi

  clarify_screen_object_form "${this_type}" "" ""
  [[ "${this_form_result}" == "quit" ]] && this_organize_choice="quit"
  return 0
}

# Shared: picker then dispatch <type>_<verb> <id>
# Args: <type> <verb> <picker_title>
function organize_action_pick_and_run() {
  local this_type="$1"
  local this_verb="$2"
  local this_title="$3"
  local this_query=$(organize_list_query "${this_type}")
  local _

  # Narrow for state-specific verbs
  case "${this_verb}" in
    complete)
      this_query=$(echo "${this_query}" | sed "s/WHERE status != 'Done'/WHERE status != 'Done'/")
      ;;
    start)
      # only Pending
      case "${this_type}" in
        task|item|project|goal|vision)
          this_query="SELECT id, name FROM $(organize_view_name "${this_type}") WHERE status = 'Pending'"
          ;;
      esac
      ;;
    stop)
      case "${this_type}" in
        task|item|project|goal|vision)
          this_query="SELECT id, name FROM $(organize_view_name "${this_type}") WHERE status = 'In Progress'"
          ;;
      esac
      ;;
    remove)
      this_query="SELECT id, name FROM $(organize_view_name "${this_type}")"
      ;;
  esac

  organize_screen_id_picker "${this_title}" "${this_query}"
  [[ "${this_organize_choice}" == "quit" ]] && return 0
  [[ -z "${this_organize_picker_id}" ]] && return 0

  clear
  workflow_print_header "organize"
  local this_fn_verb="${this_verb}"
  [[ "${this_verb}" == "remove" ]] && this_fn_verb="delete"
  "${this_type}_${this_fn_verb}" "${this_organize_picker_id}"

  printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
  if ! read _; then
    this_organize_choice="quit"
    return 0
  fi
}

function organize_action_complete() {
  local this_title="Complete $(organize_type_title "$1")"
  organize_action_pick_and_run "$1" "complete" "${this_title}"
}

function organize_action_start() {
  local this_title="Start $(organize_type_title "$1")"
  organize_action_pick_and_run "$1" "start" "${this_title}"
}

function organize_action_stop() {
  local this_title="Stop $(organize_type_title "$1")"
  organize_action_pick_and_run "$1" "stop" "${this_title}"
}

function organize_action_remove() {
  local this_title="Remove $(organize_type_title "$1")"
  organize_action_pick_and_run "$1" "remove" "${this_title}"
}

function organize_action_decide() {
  local this_type="$1"
  local _

  case "${this_type}" in
    project|goal|vision)
      clear
      workflow_print_header "organize"
      "${this_type}_decide"
      printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
      if ! read _; then
        this_organize_choice="quit"
        return 0
      fi
      ;;
    collection)
      local this_query="SELECT id, name FROM collections_view"
      organize_screen_id_picker "Decide Collection" "${this_query}"
      [[ "${this_organize_choice}" == "quit" ]] && return 0
      [[ -z "${this_organize_picker_id}" ]] && return 0
      clear
      workflow_print_header "organize"
      collection_decide "${this_organize_picker_name}"
      printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
      if ! read _; then
        this_organize_choice="quit"
        return 0
      fi
      ;;
  esac
}
