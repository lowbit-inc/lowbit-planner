#!/bin/bash

# Dependences
source ./libs/utils/color.sh
source ./libs/utils/datetime.sh
source ./libs/utils/log.sh
source ./libs/utils/test.sh

# Start
log_print info "Starting test scenarios"

# Test Scenarios
test_command_output "Libs - Utils - Datetime - Get week from date" "datetime_get_week_from_date 2026-03-17" "2026W11"
test_command_output "System Command - help"     "./plan.sh help" "Lowbit Planner - Main Help"
test_command_output "System Command - version"  "./plan.sh version" "lowbit-planner"
test_command_output "Inbox - main"  "./plan.sh inbox" "Lowbit Planner - Inbox"
test_command_output "Inbox - Adding item to inbox"  "./plan.sh inbox add This is a test" "Item added to inbox"

# End
log_print info "End of test scenarios - ${color_bold}${color_green}All Passed${color_reset}"