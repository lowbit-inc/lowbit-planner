#!/bin/bash

##############
# Properties #
##############

system_short_name="lowbit-planner"
system_long_name="Lowbit Planner"
system_version="0.2.1"
system_basename="$(basename $0)"

###########
# Methods #
###########

function system_get_version() {
  echo "${system_short_name} ${system_version}"
}

function system_search() {
  if [[ ! "${1}" ]]; then
    log_print error "Missing search pattern. Usage: ${system_basename} search PATTERN"
  fi

  this_search_pattern="${1}"
  this_found=false

  log_print info "Searching for '${color_green}${this_search_pattern}${color_reset}'..."
  printf "\n"

  # Search in each entity view
  for this_entity in "inbox:inbox_view" "tasks:tasks_view" "projects:projects_view" "areas:areas_view" "goals:goals_view" "visions:visions_view" "recurrings:recurrings_view" "habits:habits_view" "collections:collections_view" "collection_items:collection_items_view" "purposes:purposes_view" "principles:principles_view"; do
    this_entity_name="${this_entity%%:*}"
    this_entity_view="${this_entity##*:}"

    this_results=$(database_run box "SELECT * FROM ${this_entity_view} WHERE name LIKE '%${this_search_pattern}%';" 2>/dev/null)

    if [[ "${this_results}" ]]; then
      printf "${color_bold}${this_entity_name}:${color_reset}\n"
      echo "${this_results}"
      printf "\n"
      this_found=true
    fi
  done

  if [[ "${this_found}" == "false" ]]; then
    log_print info "No results found for '${this_search_pattern}'"
  fi
}

function system_install() {
  log_print user "This will install ${system_short_name} as ${color_underline}plan${color_reset} in ${color_bold}/usr/local/bin${color_reset} using ${color_bold}sudo${color_reset}. Proceed?"
  if [[ -L /usr/local/bin/plan ]]; then
    log_print warn "Symlink /usr/local/bin/plan already exists — removing before reinstall"
    sudo rm /usr/local/bin/plan
  fi
  sudo ln -s $SCRIPT_DIR/$system_basename /usr/local/bin/plan
  log_print info "Installed as /usr/local/bin/plan"
}