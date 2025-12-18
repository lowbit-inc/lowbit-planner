#!/bin/bash
system_banner="Lowbit Planner"
system_version="v0.1.0-dev"
system_basename="$(basename $0)"

function system_get_version() {
  echo "${system_banner} - Version: ${system_version}"
}
