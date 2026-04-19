#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

# Args: <object_table> <decision_table> [parent_fk] [parent_id]
# When parent_fk/parent_id are empty, scope is global (no parent filter).
function decision_generate_list() {
  this_object_table="$1"
  this_decision_table="$2"
  this_parent_fk="$3"
  this_parent_id="$4"

  if [[ -n "${this_parent_fk}" ]]; then
    log_print debug "Generating decisions for ${this_object_table} ${this_parent_fk}=${this_parent_id}"
    database_run csv "INSERT OR IGNORE INTO ${this_decision_table} (${this_parent_fk}, item_id_low, item_id_high)
      SELECT a.${this_parent_fk}, a.id, b.id
      FROM ${this_object_table} a
      JOIN ${this_object_table} b
        ON a.${this_parent_fk} = b.${this_parent_fk} AND a.id < b.id
      WHERE a.${this_parent_fk} = ${this_parent_id}
        AND a.status != 'Done'
        AND b.status != 'Done';" >/dev/null
  else
    log_print debug "Generating global decisions for ${this_object_table}"
    database_run csv "INSERT OR IGNORE INTO ${this_decision_table} (item_id_low, item_id_high)
      SELECT a.id, b.id
      FROM ${this_object_table} a
      JOIN ${this_object_table} b
        ON a.id < b.id
      WHERE a.status != 'Done'
        AND b.status != 'Done';" >/dev/null
  fi

  return 0
}

# Args: <object_table> <decision_table> [parent_fk] [parent_id]
function decision_make_choice() {
  this_object_table="$1"
  this_decision_table="$2"
  this_parent_fk="$3"
  this_parent_id="$4"

  if [[ -n "${this_parent_fk}" ]]; then
    this_scope_where="WHERE ${this_parent_fk} = ${this_parent_id}"
    this_scope_and="AND ${this_parent_fk} = ${this_parent_id}"
  else
    this_scope_where=""
    this_scope_and=""
  fi

  decisions_all=$(database_run csv "SELECT COUNT(*) FROM ${this_decision_table} ${this_scope_where};")
  if [[ -n "${this_parent_fk}" ]]; then
    decisions_made=$(database_run csv "SELECT COUNT(*) FROM ${this_decision_table} WHERE ${this_parent_fk} = ${this_parent_id} AND choice_id IS NOT NULL;")
    decisions_pending=$(database_run csv "SELECT COUNT(*) FROM ${this_decision_table} WHERE ${this_parent_fk} = ${this_parent_id} AND choice_id IS NULL;")
    this_pairs=$(database_run csv "SELECT item_id_low, item_id_high FROM ${this_decision_table} WHERE ${this_parent_fk} = ${this_parent_id} AND choice_id IS NULL ORDER BY RANDOM();")
  else
    decisions_made=$(database_run csv "SELECT COUNT(*) FROM ${this_decision_table} WHERE choice_id IS NOT NULL;")
    decisions_pending=$(database_run csv "SELECT COUNT(*) FROM ${this_decision_table} WHERE choice_id IS NULL;")
    this_pairs=$(database_run csv "SELECT item_id_low, item_id_high FROM ${this_decision_table} WHERE choice_id IS NULL ORDER BY RANDOM();")
  fi

  if [[ $decisions_pending -eq 0 ]]; then
    log_print info "No decisions to be made :)"
    return 0
  fi

  for pair in $this_pairs; do
    this_item_low=$(echo "$pair" | cut -d, -f1)
    this_item_high=$(echo "$pair" | cut -d, -f2)

    this_label_low=$(database_run csv "SELECT name FROM ${this_object_table} WHERE id = ${this_item_low};" | tr -d '"')
    this_label_high=$(database_run csv "SELECT name FROM ${this_object_table} WHERE id = ${this_item_high};" | tr -d '"')

    if [[ "${LBPLAN_NOPROMPT}" == "true" ]]; then
      this_choice_id=$this_item_low
    else
      while true; do
        clear
        printf "${color_bold}Decisions${color_reset} ( ${color_gray}Total:${decisions_all} | Made:${decisions_made} | Pending:${decisions_pending}${color_reset} )\n"
        printf "\n"
        printf "  ${color_green}1)${color_reset} %s\n" "${this_label_low}"
        printf "  ${color_green}2)${color_reset} %s\n" "${this_label_high}"
        printf "\n"
        printf "  ${color_yellow}a)${color_reset} abort decision process\n"
        printf "\n"
        printf "> "
        read this_choice
        case "$this_choice" in
          "1") this_choice_id=$this_item_low ; break ;;
          "2") this_choice_id=$this_item_high ; break ;;
          "a") return 0 ;;
        esac
      done
    fi

    if [[ -n "${this_parent_fk}" ]]; then
      database_run csv "UPDATE ${this_decision_table} SET choice_id = ${this_choice_id}, decided_at = CURRENT_TIMESTAMP WHERE ${this_parent_fk} = ${this_parent_id} AND item_id_low = ${this_item_low} AND item_id_high = ${this_item_high};"
    else
      database_run csv "UPDATE ${this_decision_table} SET choice_id = ${this_choice_id}, decided_at = CURRENT_TIMESTAMP WHERE item_id_low = ${this_item_low} AND item_id_high = ${this_item_high};"
    fi
    database_run csv "UPDATE ${this_object_table} SET position = position + 1 WHERE id = ${this_choice_id};"

    ((decisions_made++))
    ((decisions_pending--))
  done

  return 0
}

# Args: <object_table> <decision_table> [parent_fk] [parent_id]
function decision_forget() {
  this_object_table="$1"
  this_decision_table="$2"
  this_parent_fk="$3"
  this_parent_id="$4"

  if [[ -n "${this_parent_fk}" ]]; then
    log_print debug "Forgetting decisions for ${this_object_table} ${this_parent_fk}=${this_parent_id}"
    database_run csv "DELETE FROM ${this_decision_table} WHERE ${this_parent_fk} = ${this_parent_id};"
    database_run csv "UPDATE ${this_object_table} SET position = 0 WHERE ${this_parent_fk} = ${this_parent_id};"
  else
    log_print debug "Forgetting all decisions for ${this_object_table}"
    database_run csv "DELETE FROM ${this_decision_table};"
    database_run csv "UPDATE ${this_object_table} SET position = 0;"
  fi

  return 0
}
