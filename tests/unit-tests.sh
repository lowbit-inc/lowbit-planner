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
test_command_output "Global Command - help"     "./plan.sh help" "Lowbit Planner - Main Help"
test_command_output "Global Command - version"  "./plan.sh version" "Lowbit Planner - Version: "

# End
log_print info "End of test scenarios"
