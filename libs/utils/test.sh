#!/bin/bash

##############
# Properties #
##############

# N/A

###########
# Methods #
###########

function test_command_output() {
  this_title="$1"
  this_command="$2"
  this_output="$3"

  # Intro
  log_print info  "--------------------------------"
  log_print info  "Test: ${this_title}"
  log_print debug "${color_gray}Command:        ${color_reset} ${this_command}"
  log_print debug "${color_gray}Expected output:${color_reset} ${this_output}"

  # Command
  $this_command | grep "${this_output}" >/dev/null 2>&1

  # Result
  this_command_rc=$?
  if [[ $this_command_rc -eq 0 ]]; then
    log_print info "Result: ${color_green}OK${color_reset}"
  else
    log_print error "Result: ${color_green}Error${color_reset}"
  fi

  log_print info  "--------------------------------"

}