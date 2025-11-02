#!/bin/bash
#
# Author: fewbits
# Date: 2025-11-01
# Description: GTD-inspired task management tool for the terminal.

########
# Libs #
########
source ./libs/area.sh
source ./libs/clarify.sh
source ./libs/collection.sh
source ./libs/database.sh
source ./libs/dependencies.sh
source ./libs/engage.sh
source ./libs/help.sh
source ./libs/inbox.sh
source ./libs/project.sh
source ./libs/recurring.sh
source ./libs/reflect.sh
source ./libs/task.sh

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
  "project")
    shift
    projectMain "$@"
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
  *)
    helpMessage
    ;;
esac
