#!/bin/bash
#
# Author: fewbits
# Date: 2025-11-01
# Description: GTD-inspired task management tool for the terminal.

##########
# Config #
##########

########
# Libs #
########
source ./libs/area.sh
source ./libs/collection.sh
source ./libs/database.sh
source ./libs/dependencies.sh
source ./libs/help.sh
source ./libs/inbox.sh
source ./libs/project.sh

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
  "collection")
    shift
    collectionMain "$@"
    ;;
  "help")
    helpMessage
    ;;
  "inbox")
    shift
    inboxMain "$@"
    ;;
  "project")
    shift
    projectMain "$@"
    ;;
  "version")
    helpVersion
    ;;
  *)
    helpMessage
    ;;
esac