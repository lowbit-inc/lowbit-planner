#!/bin/bash

# Dependences
source ./libs/utils/color.sh
source ./libs/utils/log.sh
source ./libs/utils/test.sh

# Start
log_message info "Starting test scenarios"

# Test Scenarios
test_command_output "Global Command - help"     "./plan.sh help" "Lowbit Planner - Main Help"
test_command_output "Global Command - version"  "./plan.sh version" "Lowbit Planner - Version: "

# End
log_message info "End of test scenarios"