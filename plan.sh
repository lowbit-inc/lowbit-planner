#!/bin/bash
#
# Author: fewbits
# Date: 2025-11-01
# Description: A GTD-inspired task management tool for the terminal.

########
# Libs #
########

# System
source ./libs/system/color.sh
source ./libs/system/config.sh
source ./libs/system/datetime.sh
source ./libs/system/dependencies.sh
source ./libs/system/help.sh
source ./libs/system/log.sh
source ./libs/system/system.sh

# Database
source ./libs/database/database.sh

# Objects
source ./libs/objects/inbox.sh        # Ground
source ./libs/objects/task.sh         # Ground
source ./libs/objects/recurring.sh    # Ground
source ./libs/objects/habit.sh        # Ground
source ./libs/objects/collection.sh   # Ground
source ./libs/objects/project.sh      # Horizon 1
source ./libs/objects/area.sh         # Horizon 2
source ./libs/objects/goal.sh         # Horizon 3
source ./libs/objects/vision.sh       # Horizon 4
source ./libs/objects/purpose.sh      # Horizon 5
source ./libs/objects/principle.sh    # Horizon 5

# Workflow
source ./libs/workflow/clarify.sh
source ./libs/workflow/decision.sh
source ./libs/workflow/engage.sh
source ./libs/workflow/reflect.sh

##########
# Script #
##########

log_message debug "Starting ${system_long_name}"

# Getting user args
if [[ "${1}" ]]; then
  log_message debug "User args: $@"
  user_arg="${1}"; shift # Capturing first arg
else
  log_message debug "No user args provided - calling help message"
  system_get_help
fi

case "${user_arg}" in
  # System
  "help"|"-h"|"--help")
    system_get_help
    ;;
  "install")
    system_install
    ;;
  "version"|"-v"|"--version")
    system_get_version
    ;;
  # Objects
  "area")
    area_main "$@"
    ;;
  "collection")
    collection_main "$@"
    ;;
  "goal")
    goal_main "$@"
    ;;
  "habit")
    habit_main "$@"
    ;;
  "inbox")
    inbox_main "$@"
    ;;
  "principle")
    principle_main "$@"
    ;;
  "project")
    project_main "$@"
    ;;
  "purpose")
    purpose_main "$@"
    ;;
  "recurring")
    recurring_main "$@"
    ;;
  "task")
    task_main "$@"
    ;;
  # Workflow
  "capture")
    inbox_add "$@"
    ;;
  "clarify")
    clarify_main
    ;;
  "engage")
    engage_main
    ;;
  "organize")
    clarify_main
    ;;
  "reflect")
    reflect_main
    ;;
  "vision")
    vision_main "$@"
    ;;
  # Other
  *)
    log_message warn "Unknown command (${user_arg})"
    system_get_help
    ;;
esac