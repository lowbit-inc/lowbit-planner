#!/bin/bash
help_banner="Lowbit Planner"
help_version="undefined"
help_basename="$(basename $0)"

function helpMessage() {
  echo "${help_banner} - Help Message"
  echo
  echo "> A GTD-based tool to manage your life, without leaving the terminal."
  echo
  echo "Basics:"
  echo "  ${help_basename} help (this message)"
  echo "  ${help_basename} install"
  echo "  ${help_basename} version"
  echo
  echo "Actions:"
  echo "  ${help_basename} capture ITEM_NAME"
  echo "  ${help_basename} clarify"
  echo "  ${help_basename} organize"
  echo "  ${help_basename} reflect"
  echo "  ${help_basename} engage"
  echo
  echo "Ground:"
  echo "  ${help_basename} inbox"
  echo "  ${help_basename} task"
  echo "  ${help_basename} recurring"
  echo "  ${help_basename} habit"
  echo "  ${help_basename} collection"
  echo
  echo "Horizon 1:"
  echo "  ${help_basename} project"
  echo
  echo "Horizon 2:"
  echo "  ${help_basename} area"
  echo
  echo "Horizon 3:"
  echo "  ${help_basename} goal"
  echo
  echo "Horizon 4:"
  echo "  ${help_basename} vision"
  echo
  echo "Horizon 5:"
  echo "  ${help_basename} purpose"
  echo "  ${help_basename} principle"
  echo
}

function helpVersion() {
  echo "${help_banner} - Version: ${help_version}"
}
