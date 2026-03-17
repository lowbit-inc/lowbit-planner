#!/bin/bash

##############
# Properties #
##############

###########
# Methods #
###########

function test_command_output() {
  this_title="$1"
  this_command="$2"
  this_output="$3"

  # Intro
  log_message info  "--------------------------------"
  log_message info  "Test: ${this_title}"
  log_message debug "${color_gray}Command:        ${color_reset} ${this_command}"
  log_message debug "${color_gray}Expected output:${color_reset} ${this_output}"

  # Command
  ${this_command} | grep "${this_output}" >/dev/null 2>&1

  # Result
  this_command_rc=$?
  if [[ $this_command_rc -eq 0 ]]; then
    log_message info "Result: ${color_green}OK${color_reset}"
  else
    log_message error "Result: ${color_green}Error${color_reset}"
  fi

  log_message info  "--------------------------------"

}