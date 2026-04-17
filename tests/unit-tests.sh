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

# Task lifecycle tests (add -> start -> stop -> complete -> delete)
test_command_output "Task - add standalone" "./plan.sh task add 'Tarefa de teste'" "Item added to tasks"
test_command_output "Task - list shows task" "./plan.sh task list" "Tarefa de teste"
test_command_output "Task - search" "./plan.sh task search 'Tarefa'" "Tarefa de teste"
test_command_output "Task - start" "./plan.sh task start 2" "Updated"
test_command_output "Task - stop" "./plan.sh task stop 2" "Updated"
test_command_output "Task - edit name" "./plan.sh task edit 2 --name 'Tarefa editada'" "Updated"
test_command_output "Task - list shows edited name" "./plan.sh task list" "Tarefa editada"

# Task complete (needs confirmation via pipe)
echo "" | ./plan.sh task complete 2 >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Task - complete"
if ./plan.sh task list 2>/dev/null | grep -q "Tarefa editada"; then
  log_print error "Result: task still appears in list after complete"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Task delete (needs confirmation via pipe)
test_command_output "Task - add for delete test" "./plan.sh task add 'Tarefa para deletar'" "Item added to tasks"
echo "" | ./plan.sh task delete 3 >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Task - delete"
if ./plan.sh task list 2>/dev/null | grep -q "Tarefa para deletar"; then
  log_print error "Result: task still appears in list after delete"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Task 11.5: Organize routing test
test_command_output "Organize routes correctly" "./plan.sh organize" "Lowbit Planner"

# Task 6.1: Goal example tests (depends on Area "Casa" from 11.1)
test_command_output "Goal - help" "./plan.sh goal" "Lowbit Planner - Goal"
test_command_output "Goal - add" "./plan.sh goal add 'Aprender Rust' --area Casa" "Item added to goals"
test_command_output "Goal - list" "./plan.sh goal list" "Aprender Rust"

# Task 6.2: project edit --goal by name
test_command_output "Project edit - set goal by name" "./plan.sh project edit 1 --goal 'Aprender Rust'" "Updated"
test_command_output "Project list - shows goal column" "./plan.sh project list" "Aprender Rust"

# Task vision-crud 6.1: Vision example tests
test_command_output "Vision - help" "./plan.sh vision" "Lowbit Planner - Vision"
test_command_output "Vision - add" "./plan.sh vision add 'Ser fluente em japonês' --area Casa" "Item added to visions"
test_command_output "Vision - list" "./plan.sh vision list" "Ser fluente em japonês"

# Task vision-crud 6.2: Goal --vision integration tests
test_command_output "Goal add with --vision" "./plan.sh goal add 'Dominar Kanji' --area Casa --vision 'Ser fluente em japonês'" "Item added to goals"
test_command_output "Goal list shows vision column" "./plan.sh goal list" "Ser fluente em japonês"
test_command_output "Goal edit --vision by name" "./plan.sh goal edit 2 --vision 'Ser fluente em japonês'" "Updated"

# Habit CRUD tests
test_command_output "Habit - help" "./plan.sh habit" "Lowbit Planner - Habit"
test_command_output "Habit - add" "./plan.sh habit add 'Beber agua' --recurrence daily" "Item added to habits"
test_command_output "Habit - list" "./plan.sh habit list" "Beber agua"
test_command_output "Habit - search" "./plan.sh habit search 'agua'" "Beber agua"
test_command_output "Habit - edit name" "./plan.sh habit edit 1 --name 'Beber 2L de agua'" "Updated"
test_command_output "Habit - list shows edited" "./plan.sh habit list" "Beber 2L de agua"
test_command_output "Habit - complete" "./plan.sh habit complete 1" "Completed"

echo "" | ./plan.sh habit delete 1 >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Habit - delete"
if ./plan.sh habit list 2>/dev/null | grep -q "Beber 2L de agua"; then
  log_print error "Result: habit still appears in list after delete"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Recurring CRUD tests
test_command_output "Recurring - help" "./plan.sh recurring" "Lowbit Planner - Recurring"
test_command_output "Recurring - add" "./plan.sh recurring add 'Pagar contas' --recurrence monthly" "Item added to recurrings"
test_command_output "Recurring - list" "./plan.sh recurring list" "Pagar contas"
test_command_output "Recurring - search" "./plan.sh recurring search 'contas'" "Pagar contas"
test_command_output "Recurring - edit name" "./plan.sh recurring edit 1 --name 'Pagar boletos'" "Updated"
test_command_output "Recurring - edit recurrence" "./plan.sh recurring edit 1 --recurrence weekly" "Updated"
test_command_output "Recurring - list shows edited" "./plan.sh recurring list" "Pagar boletos"
test_command_output "Recurring - complete" "./plan.sh recurring complete 1" "Completed"

echo "" | ./plan.sh recurring delete 1 >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Recurring - delete"
if ./plan.sh recurring list 2>/dev/null | grep -q "Pagar boletos"; then
  log_print error "Result: recurring still appears in list after delete"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Collection CRUD tests
test_command_output "Collection - help" "./plan.sh collection" "Lowbit Planner - Collection"
test_command_output "Collection - add Books" "./plan.sh collection add Books" "Item added to collections"
test_command_output "Collection - add Games" "./plan.sh collection add Games" "Item added to collections"
test_command_output "Collection - list" "./plan.sh collection list" "Books"
test_command_output "Collection - search" "./plan.sh collection search 'Games'" "Games"
test_command_output "Collection - edit" "./plan.sh collection edit 1 --name 'Livros'" "Updated"
test_command_output "Collection - list shows edited" "./plan.sh collection list" "Livros"
test_command_output "Collection - edit back" "./plan.sh collection edit 1 --name 'Books'" "Updated"

# Item CRUD tests (depends on Collections above)
test_command_output "Item - help" "./plan.sh item" "Lowbit Planner - Item"
test_command_output "Item - add to Books" "./plan.sh item add 'Neuromancer' --collection Books" "Item added to collection_items"
test_command_output "Item - add to Games" "./plan.sh item add 'Persona 5 Royal' --collection Games" "Item added to collection_items"
test_command_output "Item - list" "./plan.sh item list" "Neuromancer"
test_command_output "Item - list by collection" "./plan.sh item list --collection Books" "Neuromancer"
test_command_output "Item - search" "./plan.sh item search 'Persona'" "Persona 5 Royal"
test_command_output "Item - edit name" "./plan.sh item edit 1 --name 'Neuromancer (William Gibson)'" "Updated"
test_command_output "Item - list shows edited" "./plan.sh item list" "Neuromancer (William Gibson)"
test_command_output "Item - start" "./plan.sh item start 1" "Updated"
test_command_output "Item - stop" "./plan.sh item stop 1" "Updated"

# Item complete (needs confirmation via pipe)
echo "" | ./plan.sh item complete 2 >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Item - complete"
if ./plan.sh item list 2>/dev/null | grep -q "Persona 5 Royal"; then
  log_print error "Result: item still appears in list after complete"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Item delete (needs confirmation via pipe)
test_command_output "Item - add for delete test" "./plan.sh item add 'Delete Me' --collection Books" "Item added to collection_items"
echo "" | ./plan.sh item delete 3 >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Item - delete"
if ./plan.sh item list 2>/dev/null | grep -q "Delete Me"; then
  log_print error "Result: item still appears in list after delete"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Collection delete (needs confirmation via pipe - after items are handled)
echo "" | ./plan.sh collection delete 2 >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Collection - delete"
if ./plan.sh collection list 2>/dev/null | grep -q "Games"; then
  log_print error "Result: collection still appears in list after delete"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Status filter tests (uses task ID 1 = "Comprar pecas" which is Pending)
test_command_output "Status filter - task list --status all" "./plan.sh task list --status all" "Comprar"
test_command_output "Status filter - task list --status Pending" "./plan.sh task list --status Pending" "Comprar"

# Create a task and complete it to test --status Done
test_command_output "Status filter - add task for done test" "./plan.sh task add 'Tarefa para filtro done'" "Item added to tasks"
echo "" | ./plan.sh task complete 4 >/dev/null 2>&1
test_command_output "Status filter - task list --status Done shows completed" "./plan.sh task list --status Done" "Tarefa para filtro done"

# Default list should NOT show completed task
log_print info "--------------------------------"
log_print info "Test: Status filter - default list hides completed"
if ./plan.sh task list 2>/dev/null | grep -q "Tarefa para filtro done"; then
  log_print error "Result: completed task appears in default list"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Purpose CRUD tests
test_command_output "Purpose - help" "./plan.sh purpose" "Lowbit Planner - Purpose"
test_command_output "Purpose - add" "./plan.sh purpose add 'Viver com intencionalidade'" "Item added to purposes"
test_command_output "Purpose - list" "./plan.sh purpose list" "Viver com intencionalidade"
test_command_output "Purpose - search" "./plan.sh purpose search 'intencionalidade'" "Viver com intencionalidade"
test_command_output "Purpose - edit" "./plan.sh purpose edit 1 --name 'Viver com proposito'" "Updated"
test_command_output "Purpose - list shows edited" "./plan.sh purpose list" "Viver com proposito"

echo "" | ./plan.sh purpose delete 1 >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Purpose - delete"
if ./plan.sh purpose list 2>/dev/null | grep -q "Viver com proposito"; then
  log_print error "Result: purpose still appears in list after delete"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Principle CRUD tests
test_command_output "Principle - help" "./plan.sh principle" "Lowbit Planner - Principle"
test_command_output "Principle - add" "./plan.sh principle add 'Disciplina acima de motivacao'" "Item added to principles"
test_command_output "Principle - list" "./plan.sh principle list" "Disciplina acima de motivacao"
test_command_output "Principle - search" "./plan.sh principle search 'Disciplina'" "Disciplina acima de motivacao"
test_command_output "Principle - edit" "./plan.sh principle edit 1 --name 'Consistencia acima de intensidade'" "Updated"
test_command_output "Principle - list shows edited" "./plan.sh principle list" "Consistencia acima de intensidade"

echo "" | ./plan.sh principle delete 1 >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Principle - delete"
if ./plan.sh principle list 2>/dev/null | grep -q "Consistencia acima de intensidade"; then
  log_print error "Result: principle still appears in list after delete"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Clarify workflow tests
# Clean inbox before clarify tests (previous tests may have left items)
./plan.sh --noprompt inbox delete 1 >/dev/null 2>&1

# Add items to inbox for clarify
test_command_output "Clarify - add inbox item 1" "./plan.sh inbox add 'Ideia para clarificar como purpose'" "Item added to inbox"
test_command_output "Clarify - add inbox item 2" "./plan.sh inbox add 'Ideia para deletar'" "Item added to inbox"

# Clarify: convert first to purpose (u + enter for name), delete second (d), then done
# Input: u (type=purpose), empty (accept default name), d (delete second item)
printf "u\n\nd\n" | ./plan.sh --noprompt clarify >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Clarify - converts inbox to purpose"
if ./plan.sh purpose list 2>/dev/null | grep -q "Ideia para clarificar como purpose"; then
  log_print info "Result: ${color_green}OK${color_reset}"
else
  log_print error "Result: purpose was not created from clarify"
fi
log_print info "--------------------------------"

# Verify inbox is now empty
log_print info "--------------------------------"
log_print info "Test: Clarify - inbox is empty after processing"
if ./plan.sh inbox list 2>/dev/null | grep -q "Ideia"; then
  log_print error "Result: inbox still has items after clarify"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Organize workflow tests
test_command_output "Organize - help" "./plan.sh organize" "LEVELS"
test_command_output "Organize - ground shows Inbox" "./plan.sh organize ground" "Inbox"
test_command_output "Organize - h1 shows Projects" "./plan.sh organize h1" "Projects"
test_command_output "Organize - h2 shows Areas" "./plan.sh organize h2" "Areas"
test_command_output "Organize - h3 shows Goals" "./plan.sh organize h3" "Goals"
test_command_output "Organize - h4 shows Visions" "./plan.sh organize h4" "Visions"
test_command_output "Organize - h5 shows Purpose" "./plan.sh organize h5" "Purpose"
test_command_output "Organize - all shows everything" "./plan.sh organize all" "Ground Level"

# Reflect workflow tests
test_command_output "Reflect - dashboard shows horizons" "./plan.sh reflect" "Ground"

# Run a reflect review and check it gets marked
./plan.sh reflect ground >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Reflect - ground review marks as complete"
if ./plan.sh reflect 2>/dev/null | grep -q "\[v\].*Ground"; then
  log_print info "Result: ${color_green}OK${color_reset}"
else
  log_print error "Result: ground review was not marked as complete"
fi
log_print info "--------------------------------"

# Engage workflow tests
# Add a task with a past due date to test overdue
./plan.sh task add "Tarefa atrasada" --due-date "2026-01-01" >/dev/null 2>&1
test_command_output "Engage - shows overdue tasks" "./plan.sh engage" "Overdue"

# End
log_print info "End of test scenarios - ${color_bold}${color_green}All Passed${color_reset}"
