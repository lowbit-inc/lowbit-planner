#!/bin/bash

##############
# Properties #
##############

database_dir="${HOME}/.plan"
database_file="plan.db"
database_path="${database_dir}/${database_file}"

###########
# Methods #
###########

function database_check(){
  if [[ ! -f "${database_path}" ]] ; then
    echo "Database file not found. Initializing..."
    database_init
    echo
  fi
}

function database_init(){
  mkdir -p "${database_dir}"
  sqlite3 "${database_path}" < ./libs/database/database_init.sql
}

function database_run(){
  this_mode="$1"
  this_query="$@"

  sqlite3 "--${this_mode}" "${database_path}" "${this_query}"
}

##########
# Script #
##########

database_check
