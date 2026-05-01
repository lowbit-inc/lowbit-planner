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
      ground)    reflect_screen_ground_actions                                        ;;
      horizon1)  reflect_screen_horizon1_actions                                      ;;
      horizon2)  reflect_screen_horizon2_actions                                      ;;
      horizon3)  reflect_screen_horizon3_actions                                      ;;
      horizon4)  reflect_screen_horizon4_actions                                      ;;
      horizon5)  reflect_screen_horizon5_actions                                      ;;
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

# Ground is reviewed daily. Instead of listing object categories, this screen
# surfaces the two actions that resolve Ground-level state (clarify the inbox,
# decide pending collections) and only unlocks "Mark review as complete" once
# both are resolved.
function reflect_screen_ground_actions() {
  local this_choice
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Ground ═══${color_reset}\n\n"

    local this_inbox_count=$(database_run csv "SELECT count(*) FROM inbox;" | tr -d '"')
    local this_pending_collections=$(database_run csv \
      "SELECT count(*) FROM (
         SELECT a.collection_id
         FROM collection_items a
         JOIN collection_items b
           ON a.collection_id = b.collection_id AND a.id < b.id
         LEFT JOIN collection_item_decisions d
           ON d.collection_id = a.collection_id
          AND d.item_id_low  = a.id
          AND d.item_id_high = b.id
          AND d.choice_id IS NOT NULL
         WHERE a.status != 'Done'
           AND b.status != 'Done'
           AND d.choice_id IS NULL
         GROUP BY a.collection_id
       );" \
      | tr -d '"')
    [[ -z "${this_inbox_count}"          ]] && this_inbox_count=0
    [[ -z "${this_pending_collections}"  ]] && this_pending_collections=0

    if (( this_inbox_count > 0 )); then
      printf "  ${color_green}(i)${color_reset} Clarify Inbox          — ${this_inbox_count} item(s) to clarify\n"
    else
      printf "  ${color_gray}(i) Clarify Inbox          — (empty)${color_reset}\n"
    fi

    if (( this_pending_collections > 0 )); then
      printf "  ${color_green}(d)${color_reset} Decide Collections     — ${this_pending_collections} collection(s) with pending decisions\n"
    else
      printf "  ${color_gray}(d) Decide Collections     — (nothing to decide)${color_reset}\n"
    fi

    local this_mark_enabled="false"
    if (( this_inbox_count == 0 && this_pending_collections == 0 )); then
      this_mark_enabled="true"
      printf "  ${color_green}(m)${color_reset} Mark review as complete\n"
    else
      printf "  ${color_gray}(m) Mark review as complete   [blocked: clarify inbox and decide collections first]${color_reset}\n"
    fi

    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      i|I)
        if (( this_inbox_count > 0 )); then
          clarify_main
        fi
        ;;
      d|D)
        if (( this_pending_collections > 0 )); then
          reflect_screen_ground_decide_picker
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
      m|M)
        if [[ "${this_mark_enabled}" == "true" ]]; then
          reflect_mark_complete "ground" "Ground"
          return 0
        fi
        ;;
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *)   ;; # invalid - redraw
    esac
  done
}

# Numbered picker that lists collections with pending decisions and dispatches
# the chosen one straight to collection_decide — skipping the old detail screen
# to keep the daily ritual one keystroke away from action.
function reflect_screen_ground_decide_picker() {
  local this_choice
  local i
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Decide Collections ═══${color_reset}\n\n"

    local this_raw=$(sqlite3 -separator $'\t' "${database_path}" "
      SELECT c.id, c.name
      FROM collections c
      JOIN collection_items a ON a.collection_id = c.id AND a.status != 'Done'
      JOIN collection_items b ON b.collection_id = c.id AND b.status != 'Done' AND a.id < b.id
      LEFT JOIN collection_item_decisions d
        ON d.collection_id = c.id
       AND d.item_id_low   = a.id
       AND d.item_id_high  = b.id
       AND d.choice_id IS NOT NULL
      WHERE d.choice_id IS NULL
      GROUP BY c.id, c.name
      ORDER BY c.name;")
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
    printf "  Enter a ${color_green}number${color_reset} to decide, or ${color_yellow}(b)${color_reset} Back / ${color_yellow}(q)${color_reset} Quit\n\n"
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
          local _
          collection_decide "${this_col_names[$((this_choice-1))]}"
          printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
          if ! read _; then
            this_reflect_choice="quit"
            return 0
          fi
        fi
        ;;
    esac
  done
}

############
# Layer 2e1 #
# Horizon 1 (Projects) action-focused TUI — mirrors Ground.
############

# Three things must be resolved during a weekly Projects review:
#   (d) rank projects against each other
#   (n) ensure every project has at least one Next Action (task)
#   (t) rank tasks within each multi-task project
# (m) only unlocks when all three counters hit zero.
function reflect_screen_horizon1_actions() {
  local this_choice
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Horizon 1 - Projects ═══${color_reset}\n\n"

    local this_pending_projects=$(database_run csv \
      "SELECT count(*) FROM projects a
         JOIN projects b ON a.id < b.id
         LEFT JOIN project_decisions d
           ON d.item_id_low  = a.id
          AND d.item_id_high = b.id
          AND d.choice_id IS NOT NULL
        WHERE a.status != 'Done'
          AND b.status != 'Done'
          AND d.choice_id IS NULL;" \
      | tr -d '"')
    local this_projects_without_next=$(database_run csv \
      "SELECT count(*) FROM projects p
        WHERE p.status != 'Done'
          AND NOT EXISTS (
            SELECT 1 FROM tasks t
             WHERE t.project_id = p.id AND t.status != 'Done'
          );" \
      | tr -d '"')
    local this_pending_task_decides=$(database_run csv \
      "SELECT count(*) FROM (
         SELECT a.project_id
           FROM tasks a
           JOIN tasks b
             ON a.project_id = b.project_id AND a.id < b.id
           LEFT JOIN task_decisions d
             ON d.project_id  = a.project_id
            AND d.item_id_low  = a.id
            AND d.item_id_high = b.id
            AND d.choice_id IS NOT NULL
          WHERE a.status != 'Done'
            AND b.status != 'Done'
            AND a.project_id IS NOT NULL
            AND d.choice_id IS NULL
          GROUP BY a.project_id
       );" \
      | tr -d '"')
    [[ -z "${this_pending_projects}"      ]] && this_pending_projects=0
    [[ -z "${this_projects_without_next}" ]] && this_projects_without_next=0
    [[ -z "${this_pending_task_decides}"  ]] && this_pending_task_decides=0

    if (( this_pending_projects > 0 )); then
      printf "  ${color_green}(d)${color_reset} Decide Projects             — ${this_pending_projects} pending project decision(s)\n"
    else
      printf "  ${color_gray}(d) Decide Projects             — (nothing to decide)${color_reset}\n"
    fi

    if (( this_projects_without_next > 0 )); then
      printf "  ${color_green}(n)${color_reset} Add Next Actions            — ${this_projects_without_next} project(s) without next action\n"
    else
      printf "  ${color_gray}(n) Add Next Actions            — (every project has a next action)${color_reset}\n"
    fi

    if (( this_pending_task_decides > 0 )); then
      printf "  ${color_green}(t)${color_reset} Decide Tasks in Project     — ${this_pending_task_decides} project(s) with pending task decisions\n"
    else
      printf "  ${color_gray}(t) Decide Tasks in Project     — (nothing to decide)${color_reset}\n"
    fi

    local this_mark_enabled="false"
    if (( this_pending_projects == 0 && this_projects_without_next == 0 && this_pending_task_decides == 0 )); then
      this_mark_enabled="true"
      printf "  ${color_green}(m)${color_reset} Mark review as complete\n"
    else
      printf "  ${color_gray}(m) Mark review as complete   [blocked: resolve project decisions, next actions and task decisions first]${color_reset}\n"
    fi

    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      d|D)
        if (( this_pending_projects > 0 )); then
          local _
          clear
          workflow_print_header "reflect"
          project_decide
          printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
          if ! read _; then
            this_reflect_choice="quit"
            return 0
          fi
        fi
        ;;
      n|N)
        if (( this_projects_without_next > 0 )); then
          reflect_screen_horizon1_next_action_picker
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
      t|T)
        if (( this_pending_task_decides > 0 )); then
          reflect_screen_horizon1_decide_tasks_picker
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
      m|M)
        if [[ "${this_mark_enabled}" == "true" ]]; then
          reflect_mark_complete "horizon1" "Horizon 1"
          return 0
        fi
        ;;
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *)   ;; # invalid - redraw
    esac
  done
}

# Picker of projects that have no pending task; opens the clarify task form
# pre-filled with the chosen project so the user only types the task name.
function reflect_screen_horizon1_next_action_picker() {
  local this_choice
  local i
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Add Next Actions ═══${color_reset}\n\n"

    local this_raw=$(sqlite3 -separator $'\t' "${database_path}" "
      SELECT p.id, p.name
        FROM projects p
       WHERE p.status != 'Done'
         AND NOT EXISTS (
           SELECT 1 FROM tasks t
            WHERE t.project_id = p.id AND t.status != 'Done'
         )
       ORDER BY p.name;")
    local -a this_proj_ids=()
    local -a this_proj_names=()
    if [[ -n "${this_raw}" ]]; then
      local id name
      while IFS=$'\t' read -r id name; do
        this_proj_ids+=("${id}")
        this_proj_names+=("${name}")
      done <<< "${this_raw}"
    fi
    if [[ ${#this_proj_ids[@]} -eq 0 ]]; then
      printf "  ${color_gray}(none)${color_reset}\n\n"
    else
      for i in "${!this_proj_ids[@]}"; do
        printf "  ${color_green}(%d)${color_reset} %s\n" "$((i+1))" "${this_proj_names[$i]}"
      done
      printf "\n"
    fi

    printf "  ---\n"
    printf "  Enter a ${color_green}number${color_reset} to add a task, or ${color_yellow}(b)${color_reset} Back / ${color_yellow}(q)${color_reset} Quit\n\n"
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
        if (( this_choice >= 1 && this_choice <= ${#this_proj_ids[@]} )); then
          clarify_screen_object_form "task" "" "" "${this_proj_names[$((this_choice-1))]}"
          [[ "${this_form_result}" == "quit" ]] && this_reflect_choice="quit" && return 0
        fi
        ;;
    esac
  done
}

# Picker of projects with pending task decisions; dispatches the chosen one to
# task_decide.
function reflect_screen_horizon1_decide_tasks_picker() {
  local this_choice
  local i
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Decide Tasks in Project ═══${color_reset}\n\n"

    local this_raw=$(sqlite3 -separator $'\t' "${database_path}" "
      SELECT p.id, p.name
        FROM projects p
        JOIN tasks a ON a.project_id = p.id AND a.status != 'Done'
        JOIN tasks b ON b.project_id = p.id AND b.status != 'Done' AND a.id < b.id
        LEFT JOIN task_decisions d
          ON d.project_id   = p.id
         AND d.item_id_low  = a.id
         AND d.item_id_high = b.id
         AND d.choice_id IS NOT NULL
       WHERE d.choice_id IS NULL
       GROUP BY p.id, p.name
       ORDER BY p.name;")
    local -a this_proj_ids=()
    local -a this_proj_names=()
    if [[ -n "${this_raw}" ]]; then
      local id name
      while IFS=$'\t' read -r id name; do
        this_proj_ids+=("${id}")
        this_proj_names+=("${name}")
      done <<< "${this_raw}"
    fi
    if [[ ${#this_proj_ids[@]} -eq 0 ]]; then
      printf "  ${color_gray}(none)${color_reset}\n\n"
    else
      for i in "${!this_proj_ids[@]}"; do
        printf "  ${color_green}(%d)${color_reset} %s\n" "$((i+1))" "${this_proj_names[$i]}"
      done
      printf "\n"
    fi

    printf "  ---\n"
    printf "  Enter a ${color_green}number${color_reset} to decide, or ${color_yellow}(b)${color_reset} Back / ${color_yellow}(q)${color_reset} Quit\n\n"
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
        if (( this_choice >= 1 && this_choice <= ${#this_proj_ids[@]} )); then
          local _
          task_decide "${this_proj_names[$((this_choice-1))]}"
          printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
          if ! read _; then
            this_reflect_choice="quit"
            return 0
          fi
        fi
        ;;
    esac
  done
}

############
# Layer 2e2 #
# Horizon 2 (Areas) action-focused TUI — mirrors Ground/Horizon1.
############

# Four things must be resolved during a monthly Areas review:
#   (a) validate each area still makes sense (last_validated_at within current month)
#   (v) ensure every area has at least one Vision
#   (g) ensure every area has at least one Goal
#   (p) ensure every area has at least one Project
# (m) only unlocks when all four counters hit zero.
function reflect_screen_horizon2_actions() {
  local this_choice
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Horizon 2 - Areas ═══${color_reset}\n\n"

    local this_pending_validate=$(database_run csv \
      "SELECT count(*) FROM areas
        WHERE last_validated_at IS NULL
           OR strftime('%Y-%m', last_validated_at) != strftime('%Y-%m', 'now', 'localtime');" \
      | tr -d '"')
    local this_areas_without_vision=$(database_run csv \
      "SELECT count(*) FROM areas a
        WHERE NOT EXISTS (
          SELECT 1 FROM visions v WHERE v.area_id = a.id AND v.status != 'Done'
        );" \
      | tr -d '"')
    local this_areas_without_goal=$(database_run csv \
      "SELECT count(*) FROM areas a
        WHERE NOT EXISTS (
          SELECT 1 FROM goals g WHERE g.area_id = a.id AND g.status != 'Done'
        );" \
      | tr -d '"')
    local this_areas_without_project=$(database_run csv \
      "SELECT count(*) FROM areas a
        WHERE NOT EXISTS (
          SELECT 1 FROM projects p WHERE p.area_id = a.id AND p.status != 'Done'
        );" \
      | tr -d '"')
    [[ -z "${this_pending_validate}"        ]] && this_pending_validate=0
    [[ -z "${this_areas_without_vision}"    ]] && this_areas_without_vision=0
    [[ -z "${this_areas_without_goal}"      ]] && this_areas_without_goal=0
    [[ -z "${this_areas_without_project}"   ]] && this_areas_without_project=0

    if (( this_pending_validate > 0 )); then
      printf "  ${color_green}(a)${color_reset} Validate Areas              — ${this_pending_validate} area(s) not validated this month\n"
    else
      printf "  ${color_gray}(a) Validate Areas              — (all validated)${color_reset}\n"
    fi

    if (( this_areas_without_vision > 0 )); then
      printf "  ${color_green}(v)${color_reset} Add Visions                 — ${this_areas_without_vision} area(s) without vision\n"
    else
      printf "  ${color_gray}(v) Add Visions                 — (every area has a vision)${color_reset}\n"
    fi

    if (( this_areas_without_goal > 0 )); then
      printf "  ${color_green}(g)${color_reset} Add Goals                   — ${this_areas_without_goal} area(s) without goal\n"
    else
      printf "  ${color_gray}(g) Add Goals                   — (every area has a goal)${color_reset}\n"
    fi

    if (( this_areas_without_project > 0 )); then
      printf "  ${color_green}(p)${color_reset} Add Projects                — ${this_areas_without_project} area(s) without project\n"
    else
      printf "  ${color_gray}(p) Add Projects                — (every area has a project)${color_reset}\n"
    fi

    local this_mark_enabled="false"
    if (( this_pending_validate == 0 && this_areas_without_vision == 0 && this_areas_without_goal == 0 && this_areas_without_project == 0 )); then
      this_mark_enabled="true"
      printf "  ${color_green}(m)${color_reset} Mark review as complete\n"
    else
      printf "  ${color_gray}(m) Mark review as complete   [blocked: validate areas and ensure each has a vision, goal and project]${color_reset}\n"
    fi

    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      a|A)
        if (( this_pending_validate > 0 )); then
          reflect_screen_horizon2_validate_picker
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
      v|V)
        if (( this_areas_without_vision > 0 )); then
          reflect_screen_horizon2_add_plan_picker "vision" "Add Visions" "visions"
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
      g|G)
        if (( this_areas_without_goal > 0 )); then
          reflect_screen_horizon2_add_plan_picker "goal" "Add Goals" "goals"
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
      p|P)
        if (( this_areas_without_project > 0 )); then
          reflect_screen_horizon2_add_plan_picker "project" "Add Projects" "projects"
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
      m|M)
        if [[ "${this_mark_enabled}" == "true" ]]; then
          reflect_mark_complete "horizon2" "Horizon 2"
          return 0
        fi
        ;;
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *)   ;; # invalid - redraw
    esac
  done
}

# Picker of areas pending validation; on selection opens the validate detail screen.
function reflect_screen_horizon2_validate_picker() {
  local this_choice
  local i
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Validate Areas ═══${color_reset}\n\n"

    local this_raw=$(sqlite3 -separator $'\t' "${database_path}" "
      SELECT id, name FROM areas
       WHERE last_validated_at IS NULL
          OR strftime('%Y-%m', last_validated_at) != strftime('%Y-%m', 'now', 'localtime')
       ORDER BY name;")
    local -a this_area_ids=()
    local -a this_area_names=()
    if [[ -n "${this_raw}" ]]; then
      local id name
      while IFS=$'\t' read -r id name; do
        this_area_ids+=("${id}")
        this_area_names+=("${name}")
      done <<< "${this_raw}"
    fi
    if [[ ${#this_area_ids[@]} -eq 0 ]]; then
      printf "  ${color_gray}(none)${color_reset}\n\n"
    else
      for i in "${!this_area_ids[@]}"; do
        printf "  ${color_green}(%d)${color_reset} %s\n" "$((i+1))" "${this_area_names[$i]}"
      done
      printf "\n"
    fi

    printf "  ---\n"
    printf "  Enter a ${color_green}number${color_reset} to validate, or ${color_yellow}(b)${color_reset} Back / ${color_yellow}(q)${color_reset} Quit\n\n"
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
        if (( this_choice >= 1 && this_choice <= ${#this_area_ids[@]} )); then
          reflect_screen_horizon2_validate_detail \
            "${this_area_ids[$((this_choice-1))]}" \
            "${this_area_names[$((this_choice-1))]}"
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
    esac
  done
}

# Detail screen for a single area pending validation. Shows description and
# child counts, then offers Confirm / Delete / Skip.
function reflect_screen_horizon2_validate_detail() {
  local this_id="$1"
  local this_name="$2"
  local this_choice

  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Validate: ${this_name} ═══${color_reset}\n\n"

    local this_desc=$(database_run csv "SELECT COALESCE(description, '') FROM areas WHERE id = ${this_id};" | tr -d '"')
    local this_np=$(database_run csv "SELECT count(*) FROM projects WHERE area_id = ${this_id} AND status != 'Done';")
    local this_ng=$(database_run csv "SELECT count(*) FROM goals    WHERE area_id = ${this_id} AND status != 'Done';")
    local this_nv=$(database_run csv "SELECT count(*) FROM visions  WHERE area_id = ${this_id} AND status != 'Done';")

    if [[ -n "${this_desc}" ]]; then
      printf "  ${color_bold}Description:${color_reset} %s\n" "${this_desc}"
    else
      printf "  ${color_gray}(no description)${color_reset}\n"
    fi
    printf "  ${color_bold}Active plans:${color_reset} ${this_np} project(s), ${this_ng} goal(s), ${this_nv} vision(s)\n\n"

    printf "  Does this area still make sense?\n\n"
    printf "  ${color_green}(y)${color_reset} Confirm — bumps last_validated_at to now\n"
    printf "  ${color_green}(d)${color_reset} Delete  — removes the area (fails if it has children)\n"
    printf "  ${color_yellow}(s)${color_reset} Skip    — leave for next time\n"
    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      y|Y)
        database_run csv "UPDATE areas SET last_validated_at = datetime('now', 'localtime') WHERE id = ${this_id};"
        return 0
        ;;
      d|D)
        local _
        area_delete "${this_name}"
        printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
        if ! read _; then
          this_reflect_choice="quit"
          return 0
        fi
        return 0
        ;;
      s|S|b|B) return 0 ;;
      q|Q)     this_reflect_choice="quit" ; return 0 ;;
      *)       ;; # invalid - redraw
    esac
  done
}

# Generic picker of areas missing a given plan type (vision/goal/project). On
# selection opens the clarify form pre-filled with the chosen area name.
# Args: <type> <screen_label> <table_name>
function reflect_screen_horizon2_add_plan_picker() {
  local this_type="$1"
  local this_label="$2"
  local this_table="$3"
  local this_choice
  local i

  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ ${this_label} ═══${color_reset}\n\n"

    local this_raw=$(sqlite3 -separator $'\t' "${database_path}" "
      SELECT a.id, a.name
        FROM areas a
       WHERE NOT EXISTS (
         SELECT 1 FROM ${this_table} x
          WHERE x.area_id = a.id AND x.status != 'Done'
       )
       ORDER BY a.name;")
    local -a this_area_ids=()
    local -a this_area_names=()
    if [[ -n "${this_raw}" ]]; then
      local id name
      while IFS=$'\t' read -r id name; do
        this_area_ids+=("${id}")
        this_area_names+=("${name}")
      done <<< "${this_raw}"
    fi
    if [[ ${#this_area_ids[@]} -eq 0 ]]; then
      printf "  ${color_gray}(none)${color_reset}\n\n"
    else
      for i in "${!this_area_ids[@]}"; do
        printf "  ${color_green}(%d)${color_reset} %s\n" "$((i+1))" "${this_area_names[$i]}"
      done
      printf "\n"
    fi

    printf "  ---\n"
    printf "  Enter a ${color_green}number${color_reset} to add a ${this_type}, or ${color_yellow}(b)${color_reset} Back / ${color_yellow}(q)${color_reset} Quit\n\n"
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
        if (( this_choice >= 1 && this_choice <= ${#this_area_ids[@]} )); then
          clarify_screen_object_form "${this_type}" "" "" "" "${this_area_names[$((this_choice-1))]}"
          [[ "${this_form_result}" == "quit" ]] && this_reflect_choice="quit" && return 0
        fi
        ;;
    esac
  done
}

############
# Layer 2e3 #
# Horizon 3 (Goals) action-focused TUI — mirrors Ground/Horizon1/Horizon2.
############

# Two things must be resolved during a quarterly Goals review:
#   (d) rank goals against each other (global)
#   (p) ensure every goal has at least one Project planned
# (m) only unlocks when both counters hit zero.
function reflect_screen_horizon3_actions() {
  local this_choice
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Horizon 3 - Goals ═══${color_reset}\n\n"

    local this_pending_goals=$(database_run csv \
      "SELECT count(*) FROM goals a
         JOIN goals b ON a.id < b.id
         LEFT JOIN goal_decisions d
           ON d.item_id_low  = a.id
          AND d.item_id_high = b.id
          AND d.choice_id IS NOT NULL
        WHERE a.status != 'Done'
          AND b.status != 'Done'
          AND d.choice_id IS NULL;" \
      | tr -d '"')
    local this_goals_without_project=$(database_run csv \
      "SELECT count(*) FROM goals g
        WHERE g.status != 'Done'
          AND NOT EXISTS (
            SELECT 1 FROM projects p
             WHERE p.goal_id = g.id AND p.status != 'Done'
          );" \
      | tr -d '"')
    [[ -z "${this_pending_goals}"          ]] && this_pending_goals=0
    [[ -z "${this_goals_without_project}"  ]] && this_goals_without_project=0

    if (( this_pending_goals > 0 )); then
      printf "  ${color_green}(d)${color_reset} Decide Goals                — ${this_pending_goals} pending goal decision(s)\n"
    else
      printf "  ${color_gray}(d) Decide Goals                — (nothing to decide)${color_reset}\n"
    fi

    if (( this_goals_without_project > 0 )); then
      printf "  ${color_green}(p)${color_reset} Add Projects                — ${this_goals_without_project} goal(s) without project\n"
    else
      printf "  ${color_gray}(p) Add Projects                — (every goal has a project)${color_reset}\n"
    fi

    local this_mark_enabled="false"
    if (( this_pending_goals == 0 && this_goals_without_project == 0 )); then
      this_mark_enabled="true"
      printf "  ${color_green}(m)${color_reset} Mark review as complete\n"
    else
      printf "  ${color_gray}(m) Mark review as complete   [blocked: resolve goal decisions and ensure each goal has a project]${color_reset}\n"
    fi

    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      d|D)
        if (( this_pending_goals > 0 )); then
          local _
          clear
          workflow_print_header "reflect"
          goal_decide
          printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
          if ! read _; then
            this_reflect_choice="quit"
            return 0
          fi
        fi
        ;;
      p|P)
        if (( this_goals_without_project > 0 )); then
          reflect_screen_horizon3_add_project_picker
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
      m|M)
        if [[ "${this_mark_enabled}" == "true" ]]; then
          reflect_mark_complete "horizon3" "Horizon 3"
          return 0
        fi
        ;;
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *)   ;; # invalid - redraw
    esac
  done
}

# Picker of goals without a pending project; on selection opens the project
# clarify form pre-filled with the goal's name and area (derived from goal.area_id).
function reflect_screen_horizon3_add_project_picker() {
  local this_choice
  local i
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Add Projects ═══${color_reset}\n\n"

    local this_raw=$(sqlite3 -separator $'\t' "${database_path}" "
      SELECT g.id, g.name, COALESCE(a.name, '')
        FROM goals g
        LEFT JOIN areas a ON a.id = g.area_id
       WHERE g.status != 'Done'
         AND NOT EXISTS (
           SELECT 1 FROM projects p
            WHERE p.goal_id = g.id AND p.status != 'Done'
         )
       ORDER BY g.name;")
    local -a this_goal_ids=()
    local -a this_goal_names=()
    local -a this_area_names=()
    if [[ -n "${this_raw}" ]]; then
      local id name area
      while IFS=$'\t' read -r id name area; do
        this_goal_ids+=("${id}")
        this_goal_names+=("${name}")
        this_area_names+=("${area}")
      done <<< "${this_raw}"
    fi
    if [[ ${#this_goal_ids[@]} -eq 0 ]]; then
      printf "  ${color_gray}(none)${color_reset}\n\n"
    else
      for i in "${!this_goal_ids[@]}"; do
        printf "  ${color_green}(%d)${color_reset} %s\n" "$((i+1))" "${this_goal_names[$i]}"
      done
      printf "\n"
    fi

    printf "  ---\n"
    printf "  Enter a ${color_green}number${color_reset} to add a project, or ${color_yellow}(b)${color_reset} Back / ${color_yellow}(q)${color_reset} Quit\n\n"
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
        if (( this_choice >= 1 && this_choice <= ${#this_goal_ids[@]} )); then
          clarify_screen_object_form "project" "" "" "" \
            "${this_area_names[$((this_choice-1))]}" \
            "${this_goal_names[$((this_choice-1))]}"
          [[ "${this_form_result}" == "quit" ]] && this_reflect_choice="quit" && return 0
        fi
        ;;
    esac
  done
}

############
# Layer 2e4 #
# Horizon 4 (Visions) action-focused TUI — mirrors Horizon 3.
############

# Two things must be resolved during a biannual Visions review:
#   (d) rank visions against each other (global)
#   (g) ensure every vision has at least one Goal planned
# (m) only unlocks when both counters hit zero.
function reflect_screen_horizon4_actions() {
  local this_choice
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Horizon 4 - Visions ═══${color_reset}\n\n"

    local this_pending_visions=$(database_run csv \
      "SELECT count(*) FROM visions a
         JOIN visions b ON a.id < b.id
         LEFT JOIN vision_decisions d
           ON d.item_id_low  = a.id
          AND d.item_id_high = b.id
          AND d.choice_id IS NOT NULL
        WHERE a.status != 'Done'
          AND b.status != 'Done'
          AND d.choice_id IS NULL;" \
      | tr -d '"')
    local this_visions_without_goal=$(database_run csv \
      "SELECT count(*) FROM visions v
        WHERE v.status != 'Done'
          AND NOT EXISTS (
            SELECT 1 FROM goals g
             WHERE g.vision_id = v.id AND g.status != 'Done'
          );" \
      | tr -d '"')
    [[ -z "${this_pending_visions}"        ]] && this_pending_visions=0
    [[ -z "${this_visions_without_goal}"   ]] && this_visions_without_goal=0

    if (( this_pending_visions > 0 )); then
      printf "  ${color_green}(d)${color_reset} Decide Visions              — ${this_pending_visions} pending vision decision(s)\n"
    else
      printf "  ${color_gray}(d) Decide Visions              — (nothing to decide)${color_reset}\n"
    fi

    if (( this_visions_without_goal > 0 )); then
      printf "  ${color_green}(g)${color_reset} Add Goals                   — ${this_visions_without_goal} vision(s) without goal\n"
    else
      printf "  ${color_gray}(g) Add Goals                   — (every vision has a goal)${color_reset}\n"
    fi

    local this_mark_enabled="false"
    if (( this_pending_visions == 0 && this_visions_without_goal == 0 )); then
      this_mark_enabled="true"
      printf "  ${color_green}(m)${color_reset} Mark review as complete\n"
    else
      printf "  ${color_gray}(m) Mark review as complete   [blocked: resolve vision decisions and ensure each vision has a goal]${color_reset}\n"
    fi

    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      d|D)
        if (( this_pending_visions > 0 )); then
          local _
          clear
          workflow_print_header "reflect"
          vision_decide
          printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
          if ! read _; then
            this_reflect_choice="quit"
            return 0
          fi
        fi
        ;;
      g|G)
        if (( this_visions_without_goal > 0 )); then
          reflect_screen_horizon4_add_goal_picker
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
      m|M)
        if [[ "${this_mark_enabled}" == "true" ]]; then
          reflect_mark_complete "horizon4" "Horizon 4"
          return 0
        fi
        ;;
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *)   ;; # invalid - redraw
    esac
  done
}

# Picker of visions without a pending goal; on selection opens the goal clarify
# form pre-filled with the vision's name and area (derived from vision.area_id).
function reflect_screen_horizon4_add_goal_picker() {
  local this_choice
  local i
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Add Goals ═══${color_reset}\n\n"

    local this_raw=$(sqlite3 -separator $'\t' "${database_path}" "
      SELECT v.id, v.name, COALESCE(a.name, '')
        FROM visions v
        LEFT JOIN areas a ON a.id = v.area_id
       WHERE v.status != 'Done'
         AND NOT EXISTS (
           SELECT 1 FROM goals g
            WHERE g.vision_id = v.id AND g.status != 'Done'
         )
       ORDER BY v.name;")
    local -a this_vision_ids=()
    local -a this_vision_names=()
    local -a this_area_names=()
    if [[ -n "${this_raw}" ]]; then
      local id name area
      while IFS=$'\t' read -r id name area; do
        this_vision_ids+=("${id}")
        this_vision_names+=("${name}")
        this_area_names+=("${area}")
      done <<< "${this_raw}"
    fi
    if [[ ${#this_vision_ids[@]} -eq 0 ]]; then
      printf "  ${color_gray}(none)${color_reset}\n\n"
    else
      for i in "${!this_vision_ids[@]}"; do
        printf "  ${color_green}(%d)${color_reset} %s\n" "$((i+1))" "${this_vision_names[$i]}"
      done
      printf "\n"
    fi

    printf "  ---\n"
    printf "  Enter a ${color_green}number${color_reset} to add a goal, or ${color_yellow}(b)${color_reset} Back / ${color_yellow}(q)${color_reset} Quit\n\n"
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
        if (( this_choice >= 1 && this_choice <= ${#this_vision_ids[@]} )); then
          clarify_screen_object_form "goal" "" "" "" \
            "${this_area_names[$((this_choice-1))]}" \
            "" \
            "${this_vision_names[$((this_choice-1))]}"
          [[ "${this_form_result}" == "quit" ]] && this_reflect_choice="quit" && return 0
        fi
        ;;
    esac
  done
}

############
# Layer 2e5 #
# Horizon 5 (Purposes & Principles) action-focused TUI.
############

# Yearly review of life direction. Two validation tracks (purposes, principles)
# plus two free-form add actions. (m) only unlocks once both validation
# counters hit zero; the add actions don't gate completion since "missing" is
# subjective.
function reflect_screen_horizon5_actions() {
  local this_choice
  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Horizon 5 - Purposes & Principles ═══${color_reset}\n\n"

    local this_pending_purposes=$(database_run csv \
      "SELECT count(*) FROM purposes
        WHERE last_validated_at IS NULL
           OR strftime('%Y', last_validated_at) != strftime('%Y', 'now', 'localtime');" \
      | tr -d '"')
    local this_pending_principles=$(database_run csv \
      "SELECT count(*) FROM principles
        WHERE last_validated_at IS NULL
           OR strftime('%Y', last_validated_at) != strftime('%Y', 'now', 'localtime');" \
      | tr -d '"')
    [[ -z "${this_pending_purposes}"   ]] && this_pending_purposes=0
    [[ -z "${this_pending_principles}" ]] && this_pending_principles=0

    if (( this_pending_purposes > 0 )); then
      printf "  ${color_green}(p)${color_reset} Validate Purposes           — ${this_pending_purposes} purpose(s) not validated this year\n"
    else
      printf "  ${color_gray}(p) Validate Purposes           — (all validated)${color_reset}\n"
    fi

    if (( this_pending_principles > 0 )); then
      printf "  ${color_green}(r)${color_reset} Validate Principles         — ${this_pending_principles} principle(s) not validated this year\n"
    else
      printf "  ${color_gray}(r) Validate Principles         — (all validated)${color_reset}\n"
    fi

    printf "  ${color_green}(a)${color_reset} Add Purpose                 — capture a missing purpose\n"
    printf "  ${color_green}(n)${color_reset} Add Principle               — capture a missing principle\n"

    local this_mark_enabled="false"
    if (( this_pending_purposes == 0 && this_pending_principles == 0 )); then
      this_mark_enabled="true"
      printf "  ${color_green}(m)${color_reset} Mark review as complete\n"
    else
      printf "  ${color_gray}(m) Mark review as complete   [blocked: validate every purpose and principle first]${color_reset}\n"
    fi

    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      p|P)
        if (( this_pending_purposes > 0 )); then
          reflect_screen_horizon5_validate_picker "purpose" "Validate Purposes" "purposes"
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
      r|R)
        if (( this_pending_principles > 0 )); then
          reflect_screen_horizon5_validate_picker "principle" "Validate Principles" "principles"
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
      a|A)
        clarify_screen_object_form "purpose"
        [[ "${this_form_result}" == "quit" ]] && this_reflect_choice="quit" && return 0
        ;;
      n|N)
        clarify_screen_object_form "principle"
        [[ "${this_form_result}" == "quit" ]] && this_reflect_choice="quit" && return 0
        ;;
      m|M)
        if [[ "${this_mark_enabled}" == "true" ]]; then
          reflect_mark_complete "horizon5" "Horizon 5"
          return 0
        fi
        ;;
      b|B) return 0 ;;
      q|Q) this_reflect_choice="quit" ; return 0 ;;
      *)   ;; # invalid - redraw
    esac
  done
}

# Generic picker of purposes/principles pending validation; on selection opens
# the validate detail screen.
# Args: <type> <screen_label> <table_name>
function reflect_screen_horizon5_validate_picker() {
  local this_type="$1"
  local this_label="$2"
  local this_table="$3"
  local this_choice
  local i

  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ ${this_label} ═══${color_reset}\n\n"

    local this_raw=$(sqlite3 -separator $'\t' "${database_path}" "
      SELECT id, name FROM ${this_table}
       WHERE last_validated_at IS NULL
          OR strftime('%Y', last_validated_at) != strftime('%Y', 'now', 'localtime')
       ORDER BY name;")
    local -a this_ids=()
    local -a this_names=()
    if [[ -n "${this_raw}" ]]; then
      local id name
      while IFS=$'\t' read -r id name; do
        this_ids+=("${id}")
        this_names+=("${name}")
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
    printf "  Enter a ${color_green}number${color_reset} to validate, or ${color_yellow}(b)${color_reset} Back / ${color_yellow}(q)${color_reset} Quit\n\n"
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
          reflect_screen_horizon5_validate_detail \
            "${this_type}" "${this_table}" \
            "${this_ids[$((this_choice-1))]}" \
            "${this_names[$((this_choice-1))]}"
          [[ "${this_reflect_choice}" == "quit" ]] && return 0
        fi
        ;;
    esac
  done
}

# Detail screen for a single purpose/principle pending validation.
# Args: <type> <table_name> <id> <name>
function reflect_screen_horizon5_validate_detail() {
  local this_type="$1"
  local this_table="$2"
  local this_id="$3"
  local this_name="$4"
  local this_choice

  while true; do
    clear
    workflow_print_header "reflect"
    printf "${color_bold}${color_bright_blue}═══ Validate ${this_type}: ${this_name} ═══${color_reset}\n\n"

    local this_desc=$(database_run csv "SELECT COALESCE(description, '') FROM ${this_table} WHERE id = ${this_id};" | tr -d '"')
    if [[ -n "${this_desc}" ]]; then
      printf "  ${color_bold}Description:${color_reset} %s\n\n" "${this_desc}"
    else
      printf "  ${color_gray}(no description)${color_reset}\n\n"
    fi

    printf "  Does this ${this_type} still resonate?\n\n"
    printf "  ${color_green}(y)${color_reset} Confirm — bumps last_validated_at to now\n"
    printf "  ${color_green}(d)${color_reset} Delete  — removes the ${this_type}\n"
    printf "  ${color_yellow}(s)${color_reset} Skip    — leave for next time\n"
    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(q)${color_reset} Quit\n\n"
    printf "> "
    if ! read this_choice; then
      this_reflect_choice="quit"
      return 0
    fi

    case "${this_choice}" in
      y|Y)
        database_run csv "UPDATE ${this_table} SET last_validated_at = datetime('now', 'localtime') WHERE id = ${this_id};"
        return 0
        ;;
      d|D)
        local _
        ${this_type}_delete "${this_name}"
        printf "\n${color_gray}Press ENTER to return...${color_reset}\n"
        if ! read _; then
          this_reflect_choice="quit"
          return 0
        fi
        return 0
        ;;
      s|S|b|B) return 0 ;;
      q|Q)     this_reflect_choice="quit" ; return 0 ;;
      *)       ;; # invalid - redraw
    esac
  done
}

############
# Layer 2e #
# Detail screens
############

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

