#!/bin/bash

##############
# Properties #
##############

# Communication between TUI layers (set by callees, read by callers):
#   this_form_result      - "created" | "skipped" | "deleted" | "quit" | ""
#   this_picker_result    - name chosen from fk/enum picker (empty = cancelled)
#   this_last_created_name - name of the object just created by the inner-most form

###########
# Helpers #
###########

function clarify_remove_from_inbox() {
  local this_id="${1}"
  database_run box "DELETE FROM inbox WHERE id = ${this_id};" >/dev/null 2>&1
}

function clarify_print_field() {
  local num="$1"
  local label="$2"
  local value="$3"
  if [[ -n "${value}" ]]; then
    printf "  ${color_green}(%s)${color_reset} %-12s : %s\n" "${num}" "${label}" "${value}"
  else
    printf "  ${color_green}(%s)${color_reset} %-12s : ${color_gray}—${color_reset}\n" "${num}" "${label}"
  fi
}

function clarify_prompt_text() {
  local label="$1"
  local current="$2"
  this_picker_result="__UNCHANGED__"
  if [[ -n "${current}" ]]; then
    printf "  %s [%s]: " "${label}" "${current}"
  else
    printf "  %s: " "${label}"
  fi
  local this_input
  read this_input
  if [[ -n "${this_input}" ]]; then
    this_picker_result="${this_input}"
  fi
}

function clarify_prompt_date() {
  local label="$1"
  this_picker_result="__UNCHANGED__"
  printf "  %s (YYYY-MM-DD): " "${label}"
  local this_input
  read this_input
  if [[ -z "${this_input}" ]]; then
    this_picker_result="__UNCHANGED__"
  elif [[ "${this_input}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    this_picker_result="${this_input}"
  else
    this_picker_result="__INVALID__"
  fi
}

#############
# Layer 4b  #
# Enum picker
#############

# Args: <label> <value1> <value2> ...
function clarify_screen_enum_picker() {
  local this_label="$1" ; shift
  local this_values=("$@")
  this_picker_result=""

  local this_choice
  local i
  while true; do
    clear
    workflow_print_header "clarify"
    printf "${color_bold}Pick a %s${color_reset}\n\n" "${this_label}"
    for i in "${!this_values[@]}"; do
      printf "  ${color_green}(%d)${color_reset} %s\n" "$((i+1))" "${this_values[$i]}"
    done
    printf "\n"
    printf "  ${color_yellow}(c)${color_reset} Cancel\n"
    printf "\n"
    printf "> "
    if ! read this_choice; then
      this_picker_result=""
      return 0
    fi

    case "${this_choice}" in
      c|C)
        this_picker_result=""
        return 0
        ;;
      *[!0-9]*|"")
        # invalid - redraw
        ;;
      *)
        if (( this_choice >= 1 && this_choice <= ${#this_values[@]} )); then
          this_picker_result="${this_values[$((this_choice-1))]}"
          return 0
        fi
        ;;
    esac
  done
}

#############
# Layer 4   #
# FK picker #
#############

# Args: <fk_type>  (fk_type is singular: area|project|goal|vision|collection)
function clarify_screen_fk_picker() {
  local this_fk_type="$1"
  this_picker_result=""

  # Capitalize first letter for label
  local this_label="$(echo "${this_fk_type}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"

  # FK type to table name
  local this_table
  case "${this_fk_type}" in
    area)       this_table="areas" ;;
    project)    this_table="projects" ;;
    goal)       this_table="goals" ;;
    vision)     this_table="visions" ;;
    collection) this_table="collections" ;;
    *)
      log_print warn "Unknown FK type: ${this_fk_type}"
      return 0
      ;;
  esac

  local this_choice
  local i
  while true; do
    clear
    workflow_print_header "clarify"
    printf "${color_bold}Pick a %s${color_reset}\n\n" "${this_label}"

    # Query existing items (id, name)
    local this_raw
    this_raw=$(sqlite3 -separator $'\t' "${database_path}" "SELECT id, name FROM ${this_table} ORDER BY name ASC;")

    local -a this_names=()
    if [[ -n "${this_raw}" ]]; then
      local line
      while IFS=$'\t' read -r _id line; do
        this_names+=("${line}")
      done <<< "${this_raw}"
    fi

    if [[ ${#this_names[@]} -eq 0 ]]; then
      printf "  ${color_gray}(no ${this_fk_type}s yet)${color_reset}\n\n"
    else
      for i in "${!this_names[@]}"; do
        printf "  ${color_green}(%d)${color_reset} %s\n" "$((i+1))" "${this_names[$i]}"
      done
      printf "\n"
    fi

    printf "  ${color_yellow}(n)${color_reset} New %s    ${color_yellow}(c)${color_reset} Cancel\n" "${this_fk_type}"
    printf "\n"
    printf "> "
    if ! read this_choice; then
      this_picker_result=""
      return 0
    fi

    case "${this_choice}" in
      n|N)
        # Recurse: create a new FK object inline
        clarify_screen_object_form "${this_fk_type}" "" ""
        case "${this_form_result}" in
          created)
            this_picker_result="${this_last_created_name}"
            this_form_result=""
            return 0
            ;;
          quit)
            # Propagate quit up to caller
            return 0
            ;;
          *)
            # skipped/deleted/empty - stay on picker, let user choose again
            this_form_result=""
            ;;
        esac
        ;;
      c|C)
        this_picker_result=""
        return 0
        ;;
      *[!0-9]*|"")
        # invalid - redraw
        ;;
      *)
        if (( this_choice >= 1 && this_choice <= ${#this_names[@]} )); then
          this_picker_result="${this_names[$((this_choice-1))]}"
          return 0
        fi
        ;;
    esac
  done
}

#############
# Layer 3   #
# Object form
#############

# Args: <type> <inbox_id|""> <prefilled_name>
# Sets: this_form_result, this_last_created_name (on create)
function clarify_screen_object_form() {
  local this_type="$1"
  local this_inbox_id="$2"
  local this_prefilled_name="$3"
  local this_prefilled_project="$4"
  local this_prefilled_area="$5"
  local this_prefilled_goal="$6"
  local this_prefilled_vision="$7"

  local this_name="${this_prefilled_name}"
  local this_project="${this_prefilled_project}"
  local this_area="${this_prefilled_area}"
  local this_goal="${this_prefilled_goal}"
  local this_vision="${this_prefilled_vision}"
  local this_collection=""
  local this_description=""
  local this_start_date=""
  local this_due_date=""
  local this_recurrence=""

  local this_error=""
  local this_choice=""

  while true; do
    clear
    workflow_print_header "clarify"

    if [[ -n "${this_inbox_id}" ]]; then
      printf "${color_bold}Clarify as %s${color_reset}\n\n" "${this_type}"
    else
      printf "${color_bold}New %s${color_reset}\n\n" "${this_type}"
    fi

    if [[ -n "${this_error}" ]]; then
      printf "  ${color_bright_red}! %s${color_reset}\n\n" "${this_error}"
    fi

    case "${this_type}" in
      task)
        clarify_print_field 1 "Name"       "${this_name}"
        clarify_print_field 2 "Project"    "${this_project}"
        clarify_print_field 3 "Start date" "${this_start_date}"
        clarify_print_field 4 "Due date"   "${this_due_date}"
        ;;
      project)
        clarify_print_field 1 "Name"       "${this_name}"
        clarify_print_field 2 "Area"       "${this_area}"
        clarify_print_field 3 "Goal"       "${this_goal}"
        clarify_print_field 4 "Start date" "${this_start_date}"
        clarify_print_field 5 "Due date"   "${this_due_date}"
        ;;
      goal)
        clarify_print_field 1 "Name"       "${this_name}"
        clarify_print_field 2 "Area"       "${this_area}"
        clarify_print_field 3 "Vision"     "${this_vision}"
        clarify_print_field 4 "Start date" "${this_start_date}"
        clarify_print_field 5 "Due date"   "${this_due_date}"
        ;;
      vision)
        clarify_print_field 1 "Name"        "${this_name}"
        clarify_print_field 2 "Area"        "${this_area}"
        clarify_print_field 3 "Description" "${this_description}"
        clarify_print_field 4 "Start date"  "${this_start_date}"
        clarify_print_field 5 "Due date"    "${this_due_date}"
        ;;
      area)
        clarify_print_field 1 "Name"        "${this_name}"
        clarify_print_field 2 "Description" "${this_description}"
        ;;
      purpose|principle|collection)
        clarify_print_field 1 "Name" "${this_name}"
        ;;
      habit|recurring)
        clarify_print_field 1 "Name"       "${this_name}"
        clarify_print_field 2 "Recurrence" "${this_recurrence}"
        ;;
      item)
        clarify_print_field 1 "Name"       "${this_name}"
        clarify_print_field 2 "Collection" "${this_collection}"
        ;;
    esac

    printf "\n"
    printf "  ${color_green}(c)${color_reset} Create\n"
    printf "  ---\n"
    printf "  ${color_yellow}(b)${color_reset} Back    ${color_yellow}(s)${color_reset} Skip    ${color_yellow}(d)${color_reset} Delete    ${color_yellow}(q)${color_reset} Quit\n"
    printf "\n"
    printf "> "
    if ! read this_choice; then
      this_form_result="quit"
      return 0
    fi

    this_error=""

    case "${this_choice}" in
      c|C)
        # Validate required fields
        local this_validation_error=""
        case "${this_type}" in
          task|area|purpose|principle|collection)
            [[ -z "${this_name}" ]] && this_validation_error="Name is required."
            ;;
          project|goal|vision)
            if [[ -z "${this_name}" ]]; then
              this_validation_error="Name is required."
            elif [[ -z "${this_area}" ]]; then
              this_validation_error="Area is required."
            fi
            ;;
          habit|recurring)
            if [[ -z "${this_name}" ]]; then
              this_validation_error="Name is required."
            elif [[ -z "${this_recurrence}" ]]; then
              this_validation_error="Recurrence is required."
            fi
            ;;
          item)
            if [[ -z "${this_name}" ]]; then
              this_validation_error="Name is required."
            elif [[ -z "${this_collection}" ]]; then
              this_validation_error="Collection is required."
            fi
            ;;
        esac

        if [[ -n "${this_validation_error}" ]]; then
          this_error="${this_validation_error}"
          continue
        fi

        # Build args and call *_add
        local this_args
        case "${this_type}" in
          task)
            this_args=("${this_name}")
            [[ -n "${this_project}" ]] && this_args+=("--project" "${this_project}")
            [[ -n "${this_start_date}" ]] && this_args+=("--start-date" "${this_start_date}")
            [[ -n "${this_due_date}" ]] && this_args+=("--due-date" "${this_due_date}")
            task_add "${this_args[@]}"
            ;;
          project)
            this_args=("${this_name}" "--area" "${this_area}")
            [[ -n "${this_goal}" ]] && this_args+=("--goal" "${this_goal}")
            [[ -n "${this_start_date}" ]] && this_args+=("--start-date" "${this_start_date}")
            [[ -n "${this_due_date}" ]] && this_args+=("--due-date" "${this_due_date}")
            project_add "${this_args[@]}"
            ;;
          goal)
            this_args=("${this_name}" "--area" "${this_area}")
            [[ -n "${this_vision}" ]] && this_args+=("--vision" "${this_vision}")
            [[ -n "${this_start_date}" ]] && this_args+=("--start-date" "${this_start_date}")
            [[ -n "${this_due_date}" ]] && this_args+=("--due-date" "${this_due_date}")
            goal_add "${this_args[@]}"
            ;;
          vision)
            this_args=("${this_name}" "--area" "${this_area}")
            [[ -n "${this_description}" ]] && this_args+=("--description" "${this_description}")
            [[ -n "${this_start_date}" ]] && this_args+=("--start-date" "${this_start_date}")
            [[ -n "${this_due_date}" ]] && this_args+=("--due-date" "${this_due_date}")
            vision_add "${this_args[@]}"
            ;;
          area)
            this_args=("${this_name}")
            [[ -n "${this_description}" ]] && this_args+=("--description" "${this_description}")
            area_add "${this_args[@]}"
            ;;
          purpose)
            purpose_add "${this_name}"
            ;;
          principle)
            principle_add "${this_name}"
            ;;
          collection)
            collection_add "${this_name}"
            ;;
          habit)
            habit_add "${this_name}" --recurrence "${this_recurrence}"
            ;;
          recurring)
            recurring_add "${this_name}" --recurrence "${this_recurrence}"
            ;;
          item)
            item_add "${this_name}" --collection "${this_collection}"
            ;;
        esac

        # Remove from inbox if applicable
        if [[ -n "${this_inbox_id}" ]]; then
          clarify_remove_from_inbox "${this_inbox_id}"
        fi

        this_form_result="created"
        this_last_created_name="${this_name}"
        return 0
        ;;
      b|B)
        this_form_result="back"
        return 0
        ;;
      s|S)
        this_form_result="skipped"
        return 0
        ;;
      d|D)
        if [[ -n "${this_inbox_id}" ]]; then
          clarify_remove_from_inbox "${this_inbox_id}"
          this_form_result="deleted"
        else
          this_form_result="skipped"
        fi
        return 0
        ;;
      q|Q)
        this_form_result="quit"
        return 0
        ;;
      1)
        clarify_prompt_text "Name" "${this_name}"
        [[ "${this_picker_result}" != "__UNCHANGED__" ]] && this_name="${this_picker_result}"
        ;;
      2)
        case "${this_type}" in
          task)
            clarify_screen_fk_picker "project"
            [[ "${this_form_result}" == "quit" ]] && return 0
            [[ -n "${this_picker_result}" ]] && this_project="${this_picker_result}"
            ;;
          project|goal|vision)
            clarify_screen_fk_picker "area"
            [[ "${this_form_result}" == "quit" ]] && return 0
            [[ -n "${this_picker_result}" ]] && this_area="${this_picker_result}"
            ;;
          area)
            clarify_prompt_text "Description" "${this_description}"
            [[ "${this_picker_result}" != "__UNCHANGED__" ]] && this_description="${this_picker_result}"
            ;;
          habit|recurring)
            clarify_screen_enum_picker "Recurrence" "daily" "weekly" "monthly" "quarterly" "biannual" "yearly"
            [[ -n "${this_picker_result}" ]] && this_recurrence="${this_picker_result}"
            ;;
          item)
            clarify_screen_fk_picker "collection"
            [[ "${this_form_result}" == "quit" ]] && return 0
            [[ -n "${this_picker_result}" ]] && this_collection="${this_picker_result}"
            ;;
          *) ;; # no field 2 for purpose/principle/collection
        esac
        ;;
      3)
        case "${this_type}" in
          task)
            clarify_prompt_date "Start date"
            case "${this_picker_result}" in
              __UNCHANGED__) ;;
              __INVALID__)   this_error="Invalid date format (YYYY-MM-DD)." ;;
              *)             this_start_date="${this_picker_result}" ;;
            esac
            ;;
          project)
            clarify_screen_fk_picker "goal"
            [[ "${this_form_result}" == "quit" ]] && return 0
            [[ -n "${this_picker_result}" ]] && this_goal="${this_picker_result}"
            ;;
          goal)
            clarify_screen_fk_picker "vision"
            [[ "${this_form_result}" == "quit" ]] && return 0
            [[ -n "${this_picker_result}" ]] && this_vision="${this_picker_result}"
            ;;
          vision)
            clarify_prompt_text "Description" "${this_description}"
            [[ "${this_picker_result}" != "__UNCHANGED__" ]] && this_description="${this_picker_result}"
            ;;
          *) ;;
        esac
        ;;
      4)
        case "${this_type}" in
          task)
            clarify_prompt_date "Due date"
            case "${this_picker_result}" in
              __UNCHANGED__) ;;
              __INVALID__)   this_error="Invalid date format (YYYY-MM-DD)." ;;
              *)             this_due_date="${this_picker_result}" ;;
            esac
            ;;
          project|goal|vision)
            clarify_prompt_date "Start date"
            case "${this_picker_result}" in
              __UNCHANGED__) ;;
              __INVALID__)   this_error="Invalid date format (YYYY-MM-DD)." ;;
              *)             this_start_date="${this_picker_result}" ;;
            esac
            ;;
          *) ;;
        esac
        ;;
      5)
        case "${this_type}" in
          project|goal|vision)
            clarify_prompt_date "Due date"
            case "${this_picker_result}" in
              __UNCHANGED__) ;;
              __INVALID__)   this_error="Invalid date format (YYYY-MM-DD)." ;;
              *)             this_due_date="${this_picker_result}" ;;
            esac
            ;;
          *) ;;
        esac
        ;;
      *)
        # Invalid input - ignore and redraw (do NOT advance)
        ;;
    esac
  done
}

#############
# Layer 2   #
# Type select
#############

# Args: <inbox_id> <inbox_name> <idx> <total>
# Sets: this_form_result
function clarify_screen_type_select() {
  local this_inbox_id="$1"
  local this_inbox_name="$2"
  local this_idx="$3"
  local this_total="$4"

  local this_choice
  while true; do
    clear
    workflow_print_header "clarify"
    printf "${color_bold}[%d/%d]${color_reset} ${color_green}%s${color_reset}\n\n" "${this_idx}" "${this_total}" "${this_inbox_name}"
    printf "  What type of object?\n"
    printf "  ${color_green}(t)${color_reset} Task       ${color_green}(r)${color_reset} Recurring   ${color_green}(h)${color_reset} Habit\n"
    printf "  ${color_green}(p)${color_reset} Project    ${color_green}(a)${color_reset} Area        ${color_green}(g)${color_reset} Goal\n"
    printf "  ${color_green}(v)${color_reset} Vision     ${color_green}(u)${color_reset} Purpose     ${color_green}(n)${color_reset} Principle\n"
    printf "  ${color_green}(c)${color_reset} Collection ${color_green}(i)${color_reset} Item\n"
    printf "  ---\n"
    printf "  ${color_yellow}(s)${color_reset} Skip       ${color_yellow}(d)${color_reset} Delete      ${color_yellow}(q)${color_reset} Quit\n"
    printf "\n"
    printf "> "
    if ! read this_choice; then
      this_form_result="quit"
      return 0
    fi

    if workflow_try_switch "${this_choice}" "clarify"; then
      this_form_result="quit"
      return 0
    fi

    case "${this_choice}" in
      t) clarify_screen_object_form "task"       "${this_inbox_id}" "${this_inbox_name}" ; [[ "${this_form_result}" != "back" ]] && return 0 ;;
      r) clarify_screen_object_form "recurring"  "${this_inbox_id}" "${this_inbox_name}" ; [[ "${this_form_result}" != "back" ]] && return 0 ;;
      h) clarify_screen_object_form "habit"      "${this_inbox_id}" "${this_inbox_name}" ; [[ "${this_form_result}" != "back" ]] && return 0 ;;
      p) clarify_screen_object_form "project"    "${this_inbox_id}" "${this_inbox_name}" ; [[ "${this_form_result}" != "back" ]] && return 0 ;;
      a) clarify_screen_object_form "area"       "${this_inbox_id}" "${this_inbox_name}" ; [[ "${this_form_result}" != "back" ]] && return 0 ;;
      g) clarify_screen_object_form "goal"       "${this_inbox_id}" "${this_inbox_name}" ; [[ "${this_form_result}" != "back" ]] && return 0 ;;
      v) clarify_screen_object_form "vision"     "${this_inbox_id}" "${this_inbox_name}" ; [[ "${this_form_result}" != "back" ]] && return 0 ;;
      u) clarify_screen_object_form "purpose"    "${this_inbox_id}" "${this_inbox_name}" ; [[ "${this_form_result}" != "back" ]] && return 0 ;;
      n) clarify_screen_object_form "principle"  "${this_inbox_id}" "${this_inbox_name}" ; [[ "${this_form_result}" != "back" ]] && return 0 ;;
      c) clarify_screen_object_form "collection" "${this_inbox_id}" "${this_inbox_name}" ; [[ "${this_form_result}" != "back" ]] && return 0 ;;
      i) clarify_screen_object_form "item"       "${this_inbox_id}" "${this_inbox_name}" ; [[ "${this_form_result}" != "back" ]] && return 0 ;;
      s)
        this_form_result="skipped"
        return 0
        ;;
      d)
        clarify_remove_from_inbox "${this_inbox_id}"
        this_form_result="deleted"
        return 0
        ;;
      q)
        this_form_result="quit"
        return 0
        ;;
      *)
        # Invalid input - redraw (do NOT skip item)
        ;;
    esac
  done
}

#############
# Layer 1   #
# Main loop #
#############

function clarify_main() {
  log_print debug "Starting Clarify workflow"

  local this_inbox_ids
  this_inbox_ids=$(sqlite3 "${database_path}" "SELECT id FROM inbox ORDER BY id ASC;")

  if [[ -z "${this_inbox_ids}" ]]; then
    log_print info "Inbox is empty. Nothing to clarify."
    return
  fi

  local this_inbox_count
  this_inbox_count=$(echo "${this_inbox_ids}" | wc -l | tr -d ' ')
  log_print info "Found ${color_green}${this_inbox_count}${color_reset} item(s) in inbox"

  local this_item_number=0
  local this_inbox_id
  local this_inbox_name
  IFS=$'\n'
  for this_inbox_id in ${this_inbox_ids}; do
    this_item_number=$((this_item_number + 1))
    this_inbox_name=$(sqlite3 "${database_path}" "SELECT name FROM inbox WHERE id = ${this_inbox_id};")

    this_form_result=""
    clarify_screen_type_select "${this_inbox_id}" "${this_inbox_name}" "${this_item_number}" "${this_inbox_count}"

    if [[ "${this_form_result}" == "quit" ]]; then
      unset IFS
      log_print info "Clarify session ended"
      return
    fi
  done
  unset IFS

  log_print info "Clarify session complete. All items processed."
}
