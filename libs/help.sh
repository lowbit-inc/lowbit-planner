#!/bin/bash
help_banner="Lowbit Planner"
help_version="undefined"

function helpMessage() {
  echo "${help_banner} - Help Message"
  echo
  echo "$(basename $0) OBJECT ACTION [args]"
  echo "$(basename $0) ACTION [args]"
  echo "$(basename $0) help (this message)"
  echo "$(basename $0) version"
  echo
  echo "OBJECTS:"
  echo "  inbox"
  echo "  task"
  echo "  recurring"
  echo "  collection"
  echo
  echo "  project"
  echo
  echo "  area"
  echo
  echo "ACTIONS:"
  echo "  capture [item_name]"
}

function helpVersion() {
  echo "${help_banner} - Version: ${help_version}"
}
