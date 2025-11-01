#!/bin/bash
help_banner="Lowbit Planner"
help_version="undefined"


function helpMessage() {
  echo "${help_banner} - Help Message"
  echo
  echo "$(basename $0) [OBJECT] [ACTION]"
  echo "$(basename $0) [ACTION]"
  echo
  echo "OBJECTS:"
  echo "  inbox"
}

function helpUsage() {
  echo "${help_banner} - Usage"
  echo "  $(basename $0) help     To learn how to use this tool"
  echo "  $(basename $0) usage    To see this message"
  echo "  $(basename $0) version  To check the current version"
}

function helpVersion() {
  echo "${help_banner} - Version: ${help_version}"
}