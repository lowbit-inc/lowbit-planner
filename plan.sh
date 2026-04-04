#!/bin/bash
#
# Author: fewbits
# Date: 2025-11-01
# Description: A GTD-inspired task management tool for the terminal.

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

########
# Libs #
########

# Utils
source ${SCRIPT_DIR}/libs/utils/color.sh
source ${SCRIPT_DIR}/libs/utils/config.sh
source ${SCRIPT_DIR}/libs/utils/datetime.sh
source ${SCRIPT_DIR}/libs/utils/dependencies.sh
source ${SCRIPT_DIR}/libs/utils/help.sh
source ${SCRIPT_DIR}/libs/utils/log.sh
source ${SCRIPT_DIR}/libs/utils/system.sh
source ${SCRIPT_DIR}/libs/utils/validate.sh

# Database
source ${SCRIPT_DIR}/libs/database/database.sh

# Objects
source ${SCRIPT_DIR}/libs/objects/generic.sh      # Basic template
source ${SCRIPT_DIR}/libs/objects/inbox.sh        # Ground
source ${SCRIPT_DIR}/libs/objects/task.sh         # Ground
source ${SCRIPT_DIR}/libs/objects/recurring.sh    # Ground
source ${SCRIPT_DIR}/libs/objects/habit.sh        # Ground
source ${SCRIPT_DIR}/libs/objects/collection.sh   # Ground
source ${SCRIPT_DIR}/libs/objects/project.sh      # Horizon 1
source ${SCRIPT_DIR}/libs/objects/area.sh         # Horizon 2
source ${SCRIPT_DIR}/libs/objects/goal.sh         # Horizon 3
source ${SCRIPT_DIR}/libs/objects/vision.sh       # Horizon 4
source ${SCRIPT_DIR}/libs/objects/purpose.sh      # Horizon 5
source ${SCRIPT_DIR}/libs/objects/principle.sh    # Horizon 5

# Workflow
source ${SCRIPT_DIR}/libs/workflow/capture.sh     # Step 1
source ${SCRIPT_DIR}/libs/workflow/clarify.sh     # Step 2
source ${SCRIPT_DIR}/libs/workflow/organize.sh    # Step 3
source ${SCRIPT_DIR}/libs/workflow/reflect.sh     # Step 4
source ${SCRIPT_DIR}/libs/workflow/engage.sh      # Step 5
source ${SCRIPT_DIR}/libs/workflow/decision.sh    # Ranking System

##########
# Script #
##########

log_print debug "Starting ${system_long_name}"

# Getting user args
if [[ "${1}" ]]; then
  log_print debug "User args: $@"
  user_arg="${1}"; shift # Capturing first arg
else
  log_print debug "No user args provided - calling help message"
  help_get_message main
fi

case "${user_arg}" in
  # System
  "help"|"-h"|"--help")
    help_get_message main
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
    capture_main "$@"
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
    log_print warn "Unknown command (${user_arg})"
    help_get_message main
    ;;
esac