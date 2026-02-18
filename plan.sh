#!/bin/bash
#
# Author: fewbits
# Date: 2025-11-01
# Description: A GTD-inspired task management tool for the terminal.

##########
# Config #
##########
#config_text_editor="vim" # Why/where is it used?

########
# Libs #
########
source ./libs/area.sh
source ./libs/clarify.sh
source ./libs/collection.sh
source ./libs/color.sh
source ./libs/database.sh
source ./libs/datetime.sh
source ./libs/decision.sh
source ./libs/dependencies.sh
source ./libs/engage.sh
source ./libs/goal.sh
source ./libs/habit.sh
source ./libs/help.sh
source ./libs/inbox.sh
source ./libs/log.sh
source ./libs/principle.sh
source ./libs/project.sh
source ./libs/purpose.sh
source ./libs/recurring.sh
source ./libs/reflect.sh
source ./libs/system.sh
source ./libs/task.sh
source ./libs/vision.sh

##########
# Script #
##########

log_message debug "Starting ${system_banner}"

if [[ "${1}" ]]; then
  user_arg="${1}" && log_message debug "User arg: ${user_arg}"
else
  log_message debug "No user arg provided - calling help message"
  system_get_help
fi

case "${1}" in
  "area")
    shift
    area_main "$@"
    ;;
  "capture")
    shift
    inbox_add "$@"
    ;;
  "clarify")
    clarify
    ;;
  "collection")
    shift
    collection_main "$@"
    ;;
  "engage")
    engage
    ;;
  "goal")
    shift
    goal_main "$@"
    ;;
  "habit")
    shift
    habit_main "$@"
    ;;
  "help")
    system_get_help
    ;;
  "inbox")
    shift
    inbox_main "$@"
    ;;
  "organize")
    clarify
    ;;
  "principle")
    shift
    principle_main "$@"
    ;;
  "project")
    shift
    project_main "$@"
    ;;
  "purpose")
    shift
    purpose_main "$@"
    ;;
  "recurring")
    shift
    recurring_main "$@"
    ;;
  "reflect")
    reflect
    ;;
  "task")
    shift
    task_main "$@"
    ;;
  "version")
    system_get_version
    ;;
  "vision")
    shift
    vision_main "$@"
    ;;
  *)
    log_message warn "Unknown command (${user_arg})"
    system_get_help
    ;;
esac