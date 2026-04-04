#!/bin/bash

##############
# Properties #
##############

system_short_name="lowbit-planner"
system_long_name="Lowbit Planner"
system_version="0.2.1-dev"
system_basename="$(basename $0)"

###########
# Methods #
###########

function system_get_version() {
  echo "${system_short_name} ${system_version}"
}

function system_install() {
  log_print user "This will install ${system_short_name} as ${color_underline}plan${color_reset} in ${color_bold}/usr/local/bin${color_reset} using ${color_bold}sudo${color_reset}. Proceed?"
  ln -s $SCRIPT_DIR/$system_basename /usr/local/bin/plan
}