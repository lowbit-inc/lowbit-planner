#!/bin/bash

##############
# Properties #
##############

###########
# Methods #
###########

function capture_main() {

  log_print debug "Starting capture workflow"

  if [[ "$1" ]]; then
    inbox_add "$@"
  else
    capture_tui
  fi
}

function capture_tui() {
  local this_idea
  local this_last_captured=""
  local this_capture_count=0

  while true; do
    clear
    printf "${color_bold}${system_long_name} - Capture${color_reset}\n\n"
    printf "  Type an idea and press ${color_green}ENTER${color_reset} to add it to the inbox.\n"
    printf "  Press ${color_yellow}q${color_reset} + ENTER or ${color_yellow}Ctrl-D${color_reset} to quit.\n\n"

    if [[ ${this_capture_count} -gt 0 ]]; then
      printf "  ${color_gray}Captured this session: ${this_capture_count}${color_reset}\n"
      printf "  ${color_gray}Last: ${color_green}${this_last_captured}${color_reset}\n\n"
    fi

    printf "> "
    if ! read this_idea; then
      printf "\n"
      return 0
    fi

    case "${this_idea}" in
      q|Q) return 0 ;;
      '')  ;; # empty input = just redraw
      *)
        inbox_add "${this_idea}" > /dev/null
        this_last_captured="${this_idea}"
        ((this_capture_count++))
        ;;
    esac
  done
}