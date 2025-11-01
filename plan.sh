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
source ./libs/database.sh
source ./libs/dependencies.sh
source ./libs/help.sh
source ./libs/inbox.sh

##########
# Script #
##########

usr_command="${1}"

case "${usr_command}" in
  "help")
    helpMessage
    ;;
  "inbox")
    shift
    inboxMain "$@"
    ;;
  "usage")
    helpUsage
    ;;
  "version")
    helpVersion
    ;;
  *)
    helpUsage
    ;;
esac