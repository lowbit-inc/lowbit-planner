#!/bin/bash
help_banner="Lowbit Planner"
help_version="undefined"

function helpMessage() {
  echo "${help_banner} - Help Message"
  echo
  echo "Basics:"
  echo "  $(basename $0) help (this message)"
  echo "  $(basename $0) version"
  echo
  echo "Actions:"
  echo "  $(basename $0) capture ITEM_NAME"
  echo "  $(basename $0) clarify"
  echo "  $(basename $0) organize"
  echo "  $(basename $0) reflect"
  echo "  $(basename $0) engage"
  echo
  echo "Ground:"
  echo "  $(basename $0) inbox SUB_COMMAND"
  echo "  $(basename $0) task SUB_COMMAND"
  echo "  $(basename $0) recurring SUB_COMMAND"
  echo "  $(basename $0) collection SUB_COMMAND"
  echo
  echo "Horizon 1:"
  echo "  $(basename $0) project SUB_COMMAND"
  echo
  echo "Horizon 2:"
  echo "  $(basename $0) area SUB_COMMAND"
  echo
  echo "Horizon 3:"
  echo "  $(basename $0) goal SUB_COMMAND"
  echo
  echo "Horizon 4:"
  echo "  $(basename $0) vision SUB_COMMAND"
  echo
  echo "Horizon 5:"
  echo "  $(basename $0) purpose SUB_COMMAND"
  echo "  $(basename $0) principle SUB_COMMAND"
  echo
}

function helpVersion() {
  echo "${help_banner} - Version: ${help_version}"
}
