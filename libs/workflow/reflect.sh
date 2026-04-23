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
    [[ -n "${this_workflow_switch}" ]] && return 0
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
    workflow_print_header "reflect"
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

    if workflow_try_switch "${this_choice}" "reflect"; then
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
# Note: color_* vars hold literal "\e[..." escape sequences that printf only
# interprets when they appear in the format string itself (not when passed as
# %s arguments). We interpolate the badge/suffix into the format string
# directly for that reason.
function reflect_print_menu_item() {
  local this_key="$1"
  local this_horizon="$2"
  local this_label="$3"
  local this_current_period="$4"

  local this_last_reviewed=$(database_run csv "SELECT last_reviewed_at FROM reviews WHERE horizon = '${this_horizon}';" | tr -d '"')
  local this_badge_fmt
  local this_suffix_fmt

  if [[ -z "${this_last_reviewed}" ]]; then
    this_badge_fmt="${color_yellow}[!]${color_reset}"
    this_suffix_fmt="${color_yellow}Never reviewed${color_reset}"
  elif reflect_is_current "${this_horizon}" "${this_last_reviewed}" "${this_current_period}"; then
    this_badge_fmt="${color_green}[v]${color_reset}"
    this_suffix_fmt="Last: ${this_last_reviewed}"
  else
    this_badge_fmt="${color_yellow}[!]${color_reset}"
    this_suffix_fmt="${color_yellow}Due${color_reset} (last: ${this_last_reviewed})"
  fi

  printf "  ${color_green}(%s)${color_reset} ${this_badge_fmt} ${color_bold}%s${color_reset} — ${this_suffix_fmt}\n" \
    "${this_key}" "${this_label}"
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
    workflow_print_header "reflect"
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

# Dispatch the (l) action to the horizon-specific list/picker screen.
# Args: <horizon>
function reflect_show_list() {
  local this_horizon="$1"
  case "${this_horizon}" in
    ground)   reflect_screen_list_ground   ;;
    horizon1) reflect_screen_list_horizon1 ;;
    horizon2) reflect_screen_list_horizon2 ;;
    horizon3) reflect_screen_list_horizon3 ;;
    horizon4) reflect_screen_list_horizon4 ;;
    horizon5) reflect_screen_list_horizon5 ;;
  esac
}

############
# Layer 2c #
# Generic numbered picker used by horizon list screens
############

# Renders a numbered list from a 2-column SQL query (id, label). Sets
# this_reflect_picker_id / this_reflect_picker_name on selection, or leaves them
# empty when the user presses (b)ack. EOF / (q)uit propagates via
# this_reflect_choice="quit".
# Args: <title> <query>
function reflect_screen_picker() {
  local this_title="$1"
  local this_query="$2"
  this_reflect_picker_id=""
  this_reflect_picker_name=""

  local this_choice
  local i
  while true; do
    clear
    workflow_print_header "reflect"
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
    printf "  Enter a ${color_green}number${color_reset} to open, or ${color_yellow}(b)${color_reset} Back / ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "

    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *[!0-9]*|"") ;; # invalid - redraw
      *)
        if (( this_choice >= 1 && this_choice <= ${#this_ids[@]} )); then
          this_reflect_picker_id="${this_ids[$((this_choice-1))]}"
          this_reflect_picker_name="${this_names[$((this_choice-1))]}"
          return 0
        fi
        ;;
    esac
  done
}

############
# Layer 2d #
# Horizon list screens (picker → detail loop)
############

function reflect_screen_list_horizon1() {
  while true; do
    reflect_screen_picker "Projects" \
      "SELECT id, name FROM projects_view WHERE status != 'Done';"
    [[ "${this_reflect_choice}" == "quit" ]] && return 0
    [[ -z "${this_reflect_picker_id}" ]] && return 0
    reflect_screen_detail_horizon1 "${this_reflect_picker_id}" "${this_reflect_picker_name}"
    [[ "${this_reflect_choice}" == "quit" ]] && return 0
  done
}

function reflect_screen_list_horizon2() {
  while true; do
    reflect_screen_picker "Areas" \
      "SELECT a.id, a.name || ' (' ||
         (SELECT COUNT(*) FROM projects WHERE area_id = a.id AND status != 'Done') || 'p, ' ||
         (SELECT COUNT(*) FROM goals    WHERE area_id = a.id AND status != 'Done') || 'g, ' ||
         (SELECT COUNT(*) FROM visions  WHERE area_id = a.id AND status != 'Done') || 'v)'
       FROM areas a ORDER BY a.name;"
    [[ "${this_reflect_choice}" == "quit" ]] && return 0
    [[ -z "${this_reflect_picker_id}" ]] && return 0
    # Picker label carries "(Np, Ng, Nv)" suffix; fetch the raw area name for filtering.
    local this_area_name
    this_area_name=$(database_run csv "SELECT name FROM areas WHERE id = ${this_reflect_picker_id};")
    reflect_screen_detail_horizon2 "${this_reflect_picker_id}" "${this_area_name}"
    [[ "${this_reflect_choice}" == "quit" ]] && return 0
  done
}

function reflect_screen_list_horizon3() {
  while true; do
    reflect_screen_picker "Goals" \
      "SELECT id, name FROM goals_view WHERE status != 'Done';"
    [[ "${this_reflect_choice}" == "quit" ]] && return 0
    [[ -z "${this_reflect_picker_id}" ]] && return 0
    reflect_screen_detail_horizon3 "${this_reflect_picker_id}" "${this_reflect_picker_name}"
    [[ "${this_reflect_choice}" == "quit" ]] && return 0
  done
}

function reflect_screen_list_horizon4() {
  while true; do
    reflect_screen_picker "Visions" \
      "SELECT id, name FROM visions_view WHERE status != 'Done';"
    [[ "${this_reflect_choice}" == "quit" ]] && return 0
    [[ -z "${this_reflect_picker_id}" ]] && return 0
    reflect_screen_detail_horizon4 "${this_reflect_picker_id}" "${this_reflect_picker_name}"
    [[ "${this_reflect_choice}" == "quit" ]] && return 0
  done
}

# Horizon 5 keeps the plain show-and-return flow — no drill-down.
function reflect_screen_list_horizon5() {
  local _
  clear
  workflow_print_header "reflect"
  reflect_review_horizon5
  printf "\n${color_gray}Press ENTER to return (or Ctrl+D to quit)...${color_reset}\n"
  if ! read _; then
    this_reflect_choice="quit"
    return 0
  fi
}

# Ground has six object types — dumping them all at once floods the screen.
# The (l) action opens this type submenu instead: each key lists one category,
# while (c) enters the existing Collections picker with drill-down.
function reflect_screen_list_ground() {
  local this_choice
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Ground ═══${color_reset}\n\n"
    printf "  Choose what to list:\n\n"
    printf "  ${color_green}(i)${color_reset} Inbox\n"
    printf "  ${color_green}(t)${color_reset} Tasks\n"
    printf "  ${color_green}(r)${color_reset} Recurring\n"
    printf "  ${color_green}(h)${color_reset} Habits\n"
    printf "  ${color_green}(c)${color_reset} Collections\n"
    printf "  ${color_green}(x)${color_reset} Collection Items\n"
    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      i|I) reflect_show_and_wait reflect_ground_section_inbox       ;;
      t|T) reflect_show_and_wait reflect_ground_section_tasks       ;;
      r|R) reflect_show_and_wait reflect_ground_section_recurring   ;;
      h|H) reflect_show_and_wait reflect_ground_section_habits      ;;
      c|C) reflect_screen_list_ground_collections                   ;;
      x|X) reflect_show_and_wait reflect_ground_section_items       ;;
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *)   ;; # invalid - redraw
    esac

    if [[ "${this_reflect_choice}" == "quit" ]]; then
      return 0
    fi
  done
}

# Numbered Collections picker — digit drills into the collection detail screen
# (which includes the (d) Decide option). (b) returns to the ground submenu.
function reflect_screen_list_ground_collections() {
  local this_choice
  local i
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Collections ═══${color_reset}\n\n"

    local this_raw=$(sqlite3 -separator $'\t' "${database_path}" "SELECT id, name FROM collections_view;")
    local -a this_col_ids=()
    local -a this_col_names=()
    if [[ -n "${this_raw}" ]]; then
      local id name
      while IFS=$'\t' read -r id name; do
        this_col_ids+=("${id}")
        this_col_names+=("${name}")
      done <<< "${this_raw}"
    fi
    if [[ ${#this_col_ids[@]} -eq 0 ]]; then
      printf "  ${color_gray}(none)${color_reset}\n\n"
    else
      for i in "${!this_col_ids[@]}"; do
        printf "  ${color_green}(%d)${color_reset} %s\n" "$((i+1))" "${this_col_names[$i]}"
      done
      printf "\n"
    fi

    printf "  ---\n"
    printf "  Enter a ${color_green}number${color_reset} to open, or ${color_yellow}(b)${color_reset} Back / ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *[!0-9]*|"") ;; # invalid - redraw
      *)
        if (( this_choice >= 1 && this_choice <= ${#this_col_ids[@]} )); then
          reflect_screen_detail_collection "${this_col_ids[$((this_choice-1))]}" "${this_col_names[$((this_choice-1))]}"
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
    esac
  done
}

# Clear, run a section renderer, wait for ENTER (or propagate quit on EOF).
# Args: <render_fn>
function reflect_show_and_wait() {
  local this_fn="$1"
  local _
  clear
  workflow_print_header "reflect"
  "${this_fn}"
  printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
  if ! read _; then
    this_reflect_choice="quit"
    return 0
  fi
}

function reflect_ground_section_inbox() {
  printf "${color_bold}${color_cyan}── Inbox ──${color_reset}\n"
  local this_inbox=$(database_run box "SELECT * FROM inbox_view")
  if [[ -n "${this_inbox}" ]]; then
    echo "${this_inbox}"
    printf "\n  ${color_yellow}Tip: Run '${system_basename} clarify' to process inbox items.${color_reset}\n"
  else
    printf "  ${color_gray}(empty)${color_reset}\n"
  fi
}

function reflect_ground_section_tasks() {
  printf "${color_bold}${color_cyan}── Active Tasks ──${color_reset}\n"
  local this_tasks=$(database_run box "SELECT * FROM tasks_view WHERE status != 'Done'")
  if [[ -n "${this_tasks}" ]]; then
    echo "${this_tasks}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
}

function reflect_ground_section_recurring() {
  printf "${color_bold}${color_cyan}── Recurring (Pending) ──${color_reset}\n"
  local this_recurrings=$(database_run box "SELECT * FROM recurrings_view WHERE status = 'Pending'")
  if [[ -n "${this_recurrings}" ]]; then
    echo "${this_recurrings}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
}

function reflect_ground_section_habits() {
  printf "${color_bold}${color_cyan}── Habits (Pending) ──${color_reset}\n"
  local this_habits=$(database_run box "SELECT * FROM habits_view WHERE status = 'Pending'")
  if [[ -n "${this_habits}" ]]; then
    echo "${this_habits}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
}

function reflect_ground_section_items() {
  printf "${color_bold}${color_cyan}── Collection Items ──${color_reset}\n"
  local this_items=$(database_run box "SELECT * FROM collection_items_view WHERE status != 'Done'")
  if [[ -n "${this_items}" ]]; then
    echo "${this_items}"
  else
    printf "  ${color_gray}(none)${color_reset}\n"
  fi
}

############
# Layer 2e #
# Detail screens
############

function reflect_screen_detail_horizon1() {
  local this_id="$1"
  local this_name="$2"
  local this_choice

  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Project: ${this_name} ═══${color_reset}\n\n"

    printf "${color_bold}${color_cyan}── Tasks ──${color_reset}\n"
    local this_tasks=$(database_run box "SELECT * FROM tasks_view WHERE project = '${this_name}' AND status != 'Done'")
    if [[ -n "${this_tasks}" ]]; then
      echo "${this_tasks}"
    else
      printf "  ${color_gray}(none)${color_reset}\n"
    fi
    printf "\n"

    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi
    case "${this_choice}" in
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *) ;; # invalid - redraw
    esac
  done
}

function reflect_screen_detail_horizon2() {
  local this_id="$1"
  local this_name="$2"
  local this_choice

  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Area: ${this_name} ═══${color_reset}\n\n"

    printf "${color_bold}${color_cyan}── Projects ──${color_reset}\n"
    local this_projects=$(database_run box "SELECT * FROM projects_view WHERE area = '${this_name}' AND status != 'Done'")
    if [[ -n "${this_projects}" ]]; then
      echo "${this_projects}"
    else
      printf "  ${color_gray}(none)${color_reset}\n"
    fi
    printf "\n"

    printf "${color_bold}${color_cyan}── Goals ──${color_reset}\n"
    local this_goals=$(database_run box "SELECT * FROM goals_view WHERE area = '${this_name}' AND status != 'Done'")
    if [[ -n "${this_goals}" ]]; then
      echo "${this_goals}"
    else
      printf "  ${color_gray}(none)${color_reset}\n"
    fi
    printf "\n"

    printf "${color_bold}${color_cyan}── Visions ──${color_reset}\n"
    local this_visions=$(database_run box "SELECT * FROM visions_view WHERE area = '${this_name}' AND status != 'Done'")
    if [[ -n "${this_visions}" ]]; then
      echo "${this_visions}"
    else
      printf "  ${color_gray}(none)${color_reset}\n"
    fi
    printf "\n"

    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi
    case "${this_choice}" in
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *) ;; # invalid - redraw
    esac
  done
}

function reflect_screen_detail_horizon3() {
  local this_id="$1"
  local this_name="$2"
  local this_choice

  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Goal: ${this_name} ═══${color_reset}\n\n"

    printf "${color_bold}${color_cyan}── Projects ──${color_reset}\n"
    local this_projects=$(database_run box "SELECT * FROM projects_view WHERE goal = '${this_name}' AND status != 'Done'")
    if [[ -n "${this_projects}" ]]; then
      echo "${this_projects}"
    else
      printf "  ${color_gray}(none)${color_reset}\n"
    fi
    printf "\n"

    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi
    case "${this_choice}" in
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *) ;; # invalid - redraw
    esac
  done
}

function reflect_screen_detail_horizon4() {
  local this_id="$1"
  local this_name="$2"
  local this_choice

  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Vision: ${this_name} ═══${color_reset}\n\n"

    printf "${color_bold}${color_cyan}── Goals ──${color_reset}\n"
    local this_goals=$(database_run box "SELECT * FROM goals_view WHERE vision = '${this_name}' AND status != 'Done'")
    if [[ -n "${this_goals}" ]]; then
      echo "${this_goals}"
    else
      printf "  ${color_gray}(none)${color_reset}\n"
    fi
    printf "\n"

    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi
    case "${this_choice}" in
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *) ;; # invalid - redraw
    esac
  done
}

function reflect_screen_detail_collection() {
  local this_id="$1"
  local this_name="$2"
  local this_choice

  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Collection: ${this_name} ═══${color_reset}\n\n"

    printf "${color_bold}${color_cyan}── Items ──${color_reset}\n"
    local this_items=$(database_run box "SELECT * FROM collection_items_view WHERE collection = '${this_name}' AND status != 'Done'")
    if [[ -n "${this_items}" ]]; then
      echo "${this_items}"
    else
      printf "  ${color_gray}(none)${color_reset}\n"
    fi
    printf "\n"

    printf "  ---\n"
    printf "  ${color_green}(d)${color_reset} Decide (rank items)\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi
    case "${this_choice}" in
      d|D)
        collection_decide "${this_name}"
        local _
        printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
        if ! read _; then
          this_reflect_choice="quit"
          return 0
        fi
        ;;
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *) ;; # invalid - redraw
    esac
  done
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
  workflow_print_header "reflect"
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
