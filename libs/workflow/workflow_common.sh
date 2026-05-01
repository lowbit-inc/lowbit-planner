#!/bin/bash

##############
# Properties #
##############

# GTD flow order — also the order shown in the tab bar.
workflow_modes=("capture" "clarify" "organize" "reflect" "engage")
workflow_mode_keys=("C" "L" "O" "R" "E")

# Cross-TUI navigation: root-level read loops set this_workflow_switch to one of
# the mode names. Each *_main function must check it after its root screen
# returns and bail out so workflow_dispatch can re-enter the target mode.
this_workflow_switch=""

###########
# Methods #
###########

# Render the shared header for a TUI screen. The current mode tab is bold+green,
# the others gray. Also shows the uppercase shortcut in brackets.
# Args: <current_mode>
function workflow_print_header() {
  local this_current="$1"
  local i mode key
  local this_tabs=""

  for i in "${!workflow_modes[@]}"; do
    mode="${workflow_modes[$i]}"
    key="${workflow_mode_keys[$i]}"
    if [[ "${mode}" == "${this_current}" ]]; then
      this_tabs+="${color_bold}${color_green}[${key}] ${mode}${color_reset}"
    else
      this_tabs+="${color_gray}[${key}] ${mode}${color_reset}"
    fi
    [[ $i -lt $((${#workflow_modes[@]} - 1)) ]] && this_tabs+="  "
  done

  printf "${color_bold}${system_long_name}${color_reset}\n"
  printf "${this_tabs}\n\n"
}

# Given the key the user just typed and the current mode, detect a mode switch
# request. On match (uppercase C/L/O/R/E for a *different* mode), set
# this_workflow_switch and return 0. Otherwise return 1.
# Args: <key> <current_mode>
function workflow_try_switch() {
  local this_key="$1"
  local this_current="$2"
  local this_target=""

  case "${this_key}" in
    C) this_target="capture"  ;;
    L) this_target="clarify"  ;;
    O) this_target="organize" ;;
    R) this_target="reflect"  ;;
    E) this_target="engage"   ;;
    *) return 1 ;;
  esac

  if [[ "${this_target}" == "${this_current}" ]]; then
    return 1
  fi

  this_workflow_switch="${this_target}"
  return 0
}

# Entry point used by plan.sh for any workflow TUI. Loops so that a mode switch
# triggered mid-session (via workflow_try_switch) dispatches to the new mode
# without returning to the shell.
# Args: <mode> [args...]
function workflow_dispatch() {
  local this_mode="$1" ; shift
  while [[ -n "${this_mode}" ]]; do
    this_workflow_switch=""
    case "${this_mode}" in
      capture)  capture_main  "$@" ;;
      clarify)  clarify_main  "$@" ;;
      organize) organize_main "$@" ;;
      reflect)  reflect_main  "$@" ;;
      engage)   engage_main   "$@" ;;
      *)
        log_print warn "Unknown workflow mode: ${this_mode}"
        return 1
        ;;
    esac
    this_mode="${this_workflow_switch}"
    # Switch-triggered re-dispatch enters the target mode with no args so the
    # TUI (not the one-shot path) runs.
    set --
  done
}
