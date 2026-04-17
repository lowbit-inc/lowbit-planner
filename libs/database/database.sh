#!/bin/bash

##############
# Properties #
##############

database_dir="${HOME}/.lowbit-planner"
database_file="plan.db"
database_path="${LBPLAN_DB_PATH:-${database_dir}/${database_file}}"

###########
# Methods #
###########

function database_check(){
  if [[ ! -f "${database_path}" ]] ; then
    log_print info "Database file not found. Initializing..."
    database_init
  fi
}

function database_init(){
  mkdir -p "${database_dir}"
  sqlite3 "${database_path}" < ${SCRIPT_DIR}/libs/database/database_init.sql
}

function database_run(){
  this_mode="$1" ; shift  # First arg
  this_query="$@"         # All the rest

  if [[ "${this_mode}" == "box" ]]; then
    this_term_width="${COLUMNS:-0}"
    if [[ $this_term_width -eq 0 ]]; then
      this_term_width=$(tput cols 2>/dev/null || echo 0)
    fi
    if [[ $this_term_width -gt 0 && $this_term_width -lt $config_min_terminal_width ]]; then
      sqlite3 "--line" "${database_path}" "${this_query}" | grep -v '=\s*$'
      return ${PIPESTATUS[0]}
    fi
  fi

  sqlite3 "--${this_mode}" "${database_path}" "${this_query}" ; sqlite3_rc=$?
  return $sqlite3_rc
}

##########
# Script #
##########

database_check
