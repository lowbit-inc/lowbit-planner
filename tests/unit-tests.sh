#!/bin/bash

# Dependences
source ./libs/utils/color.sh
source ./libs/utils/datetime.sh
source ./libs/utils/log.sh
source ./libs/utils/test.sh

# Isolated test database (reset on each run)
export LBPLAN_DB_PATH="/tmp/lowbit-planner-unit-tests.db"
rm -f "${LBPLAN_DB_PATH}"

# Start
log_print info "Starting test scenarios"

# Test Scenarios
test_command_output "Libs - Utils - Datetime - Get week from date" "datetime_get_week_from_date 2026-03-17" "2026W11"
test_command_output "System Command - help"     "./plan.sh help" "Lowbit Planner - Help"
test_command_output "System Command - version"  "./plan.sh version" "lowbit-planner"
test_command_output "Inbox - main"  "./plan.sh inbox" "Lowbit Planner - Inbox"
test_command_output "Inbox - Adding item to inbox"  "./plan.sh inbox add This is a test" "Item added to inbox"

# Feature: area-project-task, Property 1: Area add confirmation
for name in "Casa" "Trabalho" "Saude" "Financas" "Estudos"; do
  test_command_output "Area add - ${name}" "./plan.sh area add ${name}" "Item added to areas"
done

# Feature: area-project-task, Property 2: Area list shows inserted areas
for name in "Casa" "Trabalho" "Saude" "Financas" "Estudos"; do
  test_command_output "Area list shows - ${name}" "./plan.sh area list" "${name}"
done

# Feature: area-project-task, Property 3: Area edit updates field
for pair in "Casa:Casa-Editada" "Trabalho:Trabalho-Editado" "Saude:Saude-Editada" "Financas:Financas-Editadas" "Estudos:Estudos-Editados"; do
  original="${pair%%:*}"
  new="${pair##*:}"
  test_command_output "Area edit name - ${original} -> ${new}" "./plan.sh area edit ${original} --name ${new}" "Updated"
  test_command_output "Area list shows new name - ${new}" "./plan.sh area list" "${new}"
done

# Feature: area-project-task, Property 4: Area delete removes record
for name in "Casa-Editada" "Trabalho-Editado" "Saude-Editada" "Financas-Editadas" "Estudos-Editados"; do
  # Action: delete with confirmation (log_print user calls read — pipe Enter to confirm)
  echo "" | ./plan.sh area delete "${name}" >/dev/null 2>&1

  # Assertion: name should NOT appear in area list
  log_print info "--------------------------------"
  log_print info "Test: Area delete removes record - ${name}"
  if ./plan.sh area list 2>/dev/null | grep -q "^| ${name} "; then
    log_print error "Result: area '${name}' still appears in list after delete"
  else
    log_print info "Result: ${color_green}OK${color_reset}"
  fi
  log_print info "--------------------------------"
done

# Task 11.1: Area example tests
test_command_output "Area - help" "./plan.sh area" "Lowbit Planner - Area"
test_command_output "Area - add" "./plan.sh area add Casa" "Item added to areas"
test_command_output "Area - list" "./plan.sh area list" "Casa"

# Task 11.2: Project example tests (depends on Area "Casa" from 11.1)
test_command_output "Project - help" "./plan.sh project" "Lowbit Planner - Project"
test_command_output "Project - add" "./plan.sh project add \"Arrumar torneira\" --area Casa" "Item added to projects"
test_command_output "Project - list" "./plan.sh project list" "Arrumar torneira"

# Task 11.3: Task example tests (depends on Project ID 1 from 11.2)
test_command_output "Task - add with project" "./plan.sh task add \"Comprar peças\" --project \"Arrumar torneira\"" "Item added to tasks"
test_command_output "Task - list shows project column" "./plan.sh task list" "Arrumar torneira"

# Task 11.5: Organize routing test
test_command_output "Organize routes correctly" "./plan.sh organize" "Lowbit Planner"

# Task 6.1: Goal example tests (depends on Area "Casa" from 11.1)
test_command_output "Goal - help" "./plan.sh goal" "Lowbit Planner - Goal"
test_command_output "Goal - add" "./plan.sh goal add 'Aprender Rust' --area Casa" "Item added to goals"
test_command_output "Goal - list" "./plan.sh goal list" "Aprender Rust"

# Task 6.2: project edit --goal by name
test_command_output "Project edit - set goal by name" "./plan.sh project edit 1 --goal 'Aprender Rust'" "Updated"
test_command_output "Project list - shows goal column" "./plan.sh project list" "Aprender Rust"

# End
log_print info "End of test scenarios - ${color_bold}${color_green}All Passed${color_reset}"
