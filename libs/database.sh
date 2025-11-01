#!/bin/bash
database_dir="${HOME}/.plan"
database_file="plan.db"
database_path="${database_dir}/${database_file}"

function database_check(){
  if [[ ! -f "${database_path}" ]] ; then
    echo "Database file not found. Initializing..."
    database_init
  fi
}

function database_init(){
  mkdir -p "${database_dir}"
  sqlite3 "${database_path}" < ./libs/database_init.sql
}

function database_run(){
  this_query="$@"

  sqlite3 --table "${database_path}" "${this_query}"
}

database_check