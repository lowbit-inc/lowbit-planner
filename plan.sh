#!/bin/bash
#
# Author: fewbits
# Date: 2025-11-01
# Description: GTD-inspired task management tool for the terminal.

##########
# Config #
##########
configTextEditor="vim"

########
# Libs #
########
source ./libs/area.sh
source ./libs/clarify.sh
source ./libs/collection.sh
source ./libs/database.sh
source ./libs/datetime.sh
source ./libs/decision.sh
source ./libs/dependencies.sh
source ./libs/engage.sh
source ./libs/goal.sh
source ./libs/habit.sh
source ./libs/help.sh
source ./libs/inbox.sh
source ./libs/principle.sh
source ./libs/project.sh
source ./libs/purpose.sh
source ./libs/recurring.sh
source ./libs/reflect.sh
source ./libs/task.sh
source ./libs/vision.sh

##########
# Script #
##########

usr_command="${1}"

case "${usr_command}" in
  "area")
    shift
    areaMain "$@"
    ;;
  "capture")
    shift
    inboxAdd "$@"
    ;;
  "clarify")
    clarify
    ;;
  "collection")
    shift
    collectionMain "$@"
    ;;
  "engage")
    engage
    ;;
  "goal")
    shift
    goalMain "$@"
    ;;
  "habit")
    shift
    habitMain "$@"
    ;;
  "help")
    helpMessage
    ;;
  "inbox")
    shift
    inboxMain "$@"
    ;;
  "organize")
    clarify
    ;;
  "principle")
    shift
    principleMain "$@"
    ;;
  "project")
    shift
    projectMain "$@"
    ;;
  "purpose")
    shift
    purposeMain "$@"
    ;;
  "recurring")
    shift
    recurringMain "$@"
    ;;
  "reflect")
    reflect
    ;;
  "task")
    shift
    taskMain "$@"
    ;;
  "version")
    helpVersion
    ;;
  "vision")
    shift
    visionMain "$@"
    ;;
  *)
    helpMessage
    ;;
esac
