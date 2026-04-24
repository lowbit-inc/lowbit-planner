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

# Task 11.5: Organize routing test (now a TUI — pipe 'q' to close the menu)
test_command_output "Organize routes correctly" "printf 'q\n' | ./plan.sh --noprompt organize" "Lowbit Planner"

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

# Decide workflow tests (on Books collection - already has item 1 "Neuromancer")
test_command_output "Item - add Hyperion to Books"   "./plan.sh item add 'Hyperion'   --collection Books" "Item added"
test_command_output "Item - add Snow Crash to Books" "./plan.sh item add 'Snow Crash' --collection Books" "Item added"

# Generate pairs and auto-pick (noprompt picks option 1 = item_id_low for each pair)
test_command_output "Collection decide - generates 3 pairs" \
  "./plan.sh --noprompt collection decide Books && sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM collection_item_decisions WHERE collection_id=1'" "3"

# Idempotency: re-running does not duplicate pairs
test_command_output "Collection decide - idempotent re-run" \
  "./plan.sh --noprompt collection decide Books && sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM collection_item_decisions WHERE collection_id=1'" "3"

# Position incremented (with auto-pick=1, low ids win; items 1,4,5 in Books get positions 2,1,0 -> SUM=3)
test_command_output "Collection decide - positions incremented" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT SUM(position) FROM collection_items WHERE collection_id=1'" "3"

# --reset clears decisions and zeroes positions
./plan.sh --noprompt collection decide Books --reset >/dev/null 2>&1
test_command_output "Collection decide --reset - clears decisions" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM collection_item_decisions WHERE collection_id=1'" "0"
test_command_output "Collection decide --reset - zeroes positions" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT SUM(position) FROM collection_items WHERE collection_id=1'" "0"

# Done items are excluded from new pair generation
echo "" | ./plan.sh item complete 1 >/dev/null 2>&1
./plan.sh --noprompt collection decide Books >/dev/null 2>&1
test_command_output "Collection decide - skips Done items (only pair 4-5)" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM collection_item_decisions WHERE collection_id=1'" "1"

# Regression: stale pending pairs pointing at deleted items are scrubbed on
# the next decide run so no "ghost" comparisons remain.
./plan.sh --noprompt collection decide Books --reset >/dev/null 2>&1
./plan.sh item add 'Ghost Book' --collection Books >/dev/null 2>&1
ghost_id=$(sqlite3 $LBPLAN_DB_PATH "SELECT id FROM collection_items WHERE name='Ghost Book';")
./plan.sh --noprompt collection decide Books >/dev/null 2>&1
./plan.sh --noprompt item delete "${ghost_id}" >/dev/null 2>&1
./plan.sh --noprompt collection decide Books >/dev/null 2>&1
test_command_output "Collection decide - scrubs pending pairs for deleted items" \
  "sqlite3 \$LBPLAN_DB_PATH \"SELECT COUNT(*) FROM collection_item_decisions WHERE collection_id=1 AND choice_id IS NULL AND (item_id_low=${ghost_id} OR item_id_high=${ghost_id})\"" "0"

# Help routing
test_command_output "Collection decide - help on missing arg" "./plan.sh collection decide" "Collection Decide"

# Vision decide workflow tests (global scope)
# At this point there is 1 vision ("Ser fluente em japonês"). Add 2 more to get 3 visions -> C(3,2) = 3 pairs.
test_command_output "Vision - add Dominar Mandarim" "./plan.sh vision add 'Dominar Mandarim' --area Casa" "Item added to visions"
test_command_output "Vision - add Ler Dostoievski" "./plan.sh vision add 'Ler Dostoievski' --area Casa" "Item added to visions"

test_command_output "Vision decide - generates 3 pairs" \
  "./plan.sh --noprompt vision decide && sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM vision_decisions'" "3"
test_command_output "Vision decide - idempotent re-run" \
  "./plan.sh --noprompt vision decide && sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM vision_decisions'" "3"
test_command_output "Vision decide - positions incremented" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT SUM(position) FROM visions'" "3"

./plan.sh --noprompt vision decide --reset >/dev/null 2>&1
test_command_output "Vision decide --reset - clears decisions" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM vision_decisions'" "0"
test_command_output "Vision decide --reset - zeroes positions" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT SUM(position) FROM visions'" "0"

# Goal decide workflow tests (global scope)
# At this point there are 2 goals. Add 1 more to get 3 goals -> C(3,2) = 3 pairs.
test_command_output "Goal - add 3rd goal" "./plan.sh goal add 'Escrever um livro' --area Casa" "Item added to goals"

test_command_output "Goal decide - generates 3 pairs" \
  "./plan.sh --noprompt goal decide && sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM goal_decisions'" "3"
test_command_output "Goal decide - idempotent re-run" \
  "./plan.sh --noprompt goal decide && sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM goal_decisions'" "3"
test_command_output "Goal decide - positions incremented" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT SUM(position) FROM goals'" "3"

./plan.sh --noprompt goal decide --reset >/dev/null 2>&1
test_command_output "Goal decide --reset - clears decisions" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM goal_decisions'" "0"
test_command_output "Goal decide --reset - zeroes positions" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT SUM(position) FROM goals'" "0"

# Project decide workflow tests (global scope)
# At this point there is 1 project. Add 2 more to get 3 projects -> C(3,2) = 3 pairs.
test_command_output "Project - add 2nd project" "./plan.sh project add 'Organizar armario' --area Casa" "Item added to projects"
test_command_output "Project - add 3rd project" "./plan.sh project add 'Plantar arvore' --area Casa" "Item added to projects"

test_command_output "Project decide - generates 3 pairs" \
  "./plan.sh --noprompt project decide && sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM project_decisions'" "3"
test_command_output "Project decide - idempotent re-run" \
  "./plan.sh --noprompt project decide && sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM project_decisions'" "3"
test_command_output "Project decide - positions incremented" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT SUM(position) FROM projects'" "3"

./plan.sh --noprompt project decide --reset >/dev/null 2>&1
test_command_output "Project decide --reset - clears decisions" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT COUNT(*) FROM project_decisions'" "0"
test_command_output "Project decide --reset - zeroes positions" \
  "sqlite3 \$LBPLAN_DB_PATH 'SELECT SUM(position) FROM projects'" "0"

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
test_command_output "Status filter - add task for Done test" "./plan.sh task add 'Tarefa para filtro done'" "Item added to tasks"
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

# Clarify: convert first to purpose (u, then c to Create with pre-filled Name),
# delete second (d).
# Input sequence: u (type=purpose), c (Create - name is pre-filled from inbox),
#                 d (delete second inbox item from type-select)
printf "u\nc\nd\n" | ./plan.sh --noprompt clarify >/dev/null 2>&1
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

# Invalid input at the type-select menu must NOT advance to the next item.
# 'x' is invalid and should be ignored (screen redraws). Then 'u' + 'c' creates.
./plan.sh inbox add 'Clarify invalid key' >/dev/null 2>&1
printf "x\nu\nc\n" | ./plan.sh --noprompt clarify >/dev/null 2>&1
test_command_output "Clarify - invalid key is ignored, item still processed" \
  "./plan.sh purpose list" "Clarify invalid key"

# Required-field validation on (c) Create: pressing 'c' on a Project form with no
# Area must emit an inline error and stay on the screen. 's' then skips the item.
./plan.sh inbox add 'Proj sem area' >/dev/null 2>&1
log_print info "--------------------------------"
log_print info "Test: Clarify - Create blocks when required Area is missing"
if printf "p\nc\ns\n" | ./plan.sh --noprompt clarify 2>&1 | grep -q "Area is required"; then
  log_print info "Result: ${color_green}OK${color_reset}"
else
  log_print error "Result: Area-required error not shown"
fi
log_print info "--------------------------------"
# The skipped item must remain in the inbox
log_print info "--------------------------------"
log_print info "Test: Clarify - skipped item remains in inbox"
if ./plan.sh inbox list 2>/dev/null | grep -q "Proj sem area"; then
  log_print info "Result: ${color_green}OK${color_reset}"
else
  log_print error "Result: skipped item was removed from inbox"
fi
log_print info "--------------------------------"
# Clean the inbox so the next clarify test starts with only its own item
sqlite3 "$LBPLAN_DB_PATH" "DELETE FROM inbox;" >/dev/null 2>&1

# FK picker with (n) New: inline-create an Area from inside a Project form, then
# complete the Project using the fresh Area as its FK.
# Input sequence:
#   p           -> choose Project type
#   2           -> open Area field (FK picker)
#   n           -> New area (nested form)
#   1           -> Name field in the nested area form
#   Casa Nova   -> Name value
#   c           -> Create area (nested form exits, picker resolves to "Casa Nova")
#   c           -> Create project (back in outer form, Area is now "Casa Nova")
./plan.sh inbox add 'Novo projeto com area nova' >/dev/null 2>&1
printf "p\n2\nn\n1\nCasa Nova\nc\nc\n" | ./plan.sh --noprompt clarify >/dev/null 2>&1
test_command_output "Clarify - FK picker creates new area inline" \
  "./plan.sh area list" "Casa Nova"
test_command_output "Clarify - project created with inline-new area" \
  "./plan.sh project list" "Novo projeto com area nova"

# (b) Back from the object form returns to type-select for the same inbox item.
# Input: 't' (Task form) -> 'b' (back) -> 'u' (Purpose form) -> 'c' (Create).
# After this the item must end up as a purpose, proving the back step brought
# us back to the type-select screen instead of advancing/skipping.
./plan.sh inbox add 'Item para voltar' >/dev/null 2>&1
printf "t\nb\nu\nc\n" | ./plan.sh --noprompt clarify >/dev/null 2>&1
test_command_output "Clarify - (b) Back returns to type select" \
  "./plan.sh purpose list" "Item para voltar"

# Organize workflow tests (TUI — 3-level CRUD explorer: horizon → object → op)
#   L1 keys: g/1/2/3/4/5/q   L2 keys: (varies per horizon) b/q
#   L3 keys: l/a/c/s/x/d/r/b/q    ENTER to dismiss result screens
test_command_output "Organize - L1 menu shows horizons" \
  "printf 'q\n' | ./plan.sh --noprompt organize" "Choose a horizon"
test_command_output "Organize - L2 ground menu offers Inbox option" \
  "printf 'g\nb\nq\n' | ./plan.sh --noprompt organize" "Inbox"
test_command_output "Organize - L2 horizon5 menu offers Purpose option" \
  "printf '5\nb\nq\n' | ./plan.sh --noprompt organize" "Purpose"
test_command_output "Organize - L3 ground → inbox → list shows Inbox header" \
  "printf 'g\ni\nl\n\nb\nb\nq\n' | ./plan.sh --noprompt organize" "═══ Inbox ═══"
test_command_output "Organize - H1 skips L2 and goes direct to Project ops" \
  "printf '1\nl\n\nb\nq\n' | ./plan.sh --noprompt organize" "═══ Project ═══"
test_command_output "Organize - H2 skips L2 and goes direct to Area ops" \
  "printf '2\nb\nq\n' | ./plan.sh --noprompt organize" "═══ Area ═══"
test_command_output "Organize - H3 skips L2 and goes direct to Goal ops" \
  "printf '3\nb\nq\n' | ./plan.sh --noprompt organize" "═══ Goal ═══"
test_command_output "Organize - H4 skips L2 and goes direct to Vision ops" \
  "printf '4\nb\nq\n' | ./plan.sh --noprompt organize" "═══ Vision ═══"
test_command_output "Organize - H5 → purpose → list shows Purpose header" \
  "printf '5\nu\nl\n\nb\nb\nq\n' | ./plan.sh --noprompt organize" "═══ Purpose ═══"
test_command_output "Organize - task ops menu offers Complete" \
  "printf 'g\nt\nb\nb\nq\n' | ./plan.sh --noprompt organize" "Complete"
test_command_output "Organize - collection ops menu offers Decide" \
  "printf 'g\nc\nb\nb\nq\n' | ./plan.sh --noprompt organize" "Decide"
test_command_output "Organize - inbox ops menu offers Remove" \
  "printf 'g\ni\nb\nb\nq\n' | ./plan.sh --noprompt organize" "Remove"

# Invalid key on the menu is ignored (screen redraws); then 'g' still works
test_command_output "Organize - invalid L1 key ignored, then ground works" \
  "printf 'z\ng\nb\nq\n' | ./plan.sh --noprompt organize" "Inbox"

# Inbox add via inline prompt (only type without clarify form support)
./plan.sh --noprompt inbox delete "Novo via organize" >/dev/null 2>&1
printf "g\ni\na\nNovo via organize\n\nb\nb\nq\n" | ./plan.sh --noprompt organize >/dev/null 2>&1
test_command_output "Organize - inbox add creates item via inline prompt" \
  "./plan.sh inbox list" "Novo via organize"

# Reflect workflow tests

# Main menu appears and lists the horizons
test_command_output "Reflect - TUI menu shows horizons" \
  "printf 'q\n' | ./plan.sh --noprompt reflect" "Choose a horizon"

# Inline status label for Ground is rendered in the menu
test_command_output "Reflect - menu shows Ground label" \
  "printf 'q\n' | ./plan.sh --noprompt reflect" "Ground (Daily)"

# Pressing 'g' opens the Ground actions screen (Clarify / Decide / Mark)
test_command_output "Reflect - ground screen shows Ground header" \
  "printf 'g\nb\nq\n' | ./plan.sh --noprompt reflect" "═══ Ground ═══"

# Ground actions screen lists the three action items
test_command_output "Reflect - ground screen offers Clarify Inbox" \
  "printf 'g\nb\nq\n' | ./plan.sh --noprompt reflect" "Clarify Inbox"
test_command_output "Reflect - ground screen offers Decide Collections" \
  "printf 'g\nb\nq\n' | ./plan.sh --noprompt reflect" "Decide Collections"

# (l) on Horizon 1 shows Projects picker
test_command_output "Reflect - h1 list shows Projects" \
  "printf '1\nl\nb\nb\nq\n' | ./plan.sh --noprompt reflect" "Projects"

# (l) on Horizon 2 shows Areas picker
test_command_output "Reflect - h2 list shows Areas" \
  "printf '2\nl\nb\nb\nq\n' | ./plan.sh --noprompt reflect" "Areas"

# (l) on Horizon 3 shows Goals picker
test_command_output "Reflect - h3 list shows Goals" \
  "printf '3\nl\nb\nb\nq\n' | ./plan.sh --noprompt reflect" "Goals"

# (l) on Horizon 4 shows Visions picker
test_command_output "Reflect - h4 list shows Visions" \
  "printf '4\nl\nb\nb\nq\n' | ./plan.sh --noprompt reflect" "Visions"

# (l) on Horizon 5 shows Purposes section
test_command_output "Reflect - h5 list shows Purposes" \
  "printf '5\nl\n\nb\nq\n' | ./plan.sh --noprompt reflect" "Purposes"

# (d) Decide option is shown on Horizon 1 (supported)
test_command_output "Reflect - h1 screen shows Decide option" \
  "printf '1\nb\nq\n' | ./plan.sh --nocolor --noprompt reflect" "(d) Decide"

# (d) Decide option is NOT shown on Horizon 2 (unsupported)
log_print info "--------------------------------"
log_print info "Test: Reflect - h2 screen hides Decide option"
if printf '2\nb\nq\n' | ./plan.sh --nocolor --noprompt reflect 2>/dev/null | grep -q "(d) Decide"; then
  log_print error "Result: Decide option should not appear on h2 screen"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# (m) is blocked while inbox has items or collections have pending decisions.
test_command_output "Reflect - ground mark complete is blocked when state pending" \
  "printf 'g\nb\nq\n' | ./plan.sh --nocolor --noprompt reflect" "blocked"

# (m) marks the review as complete once state is empty; main menu shows [v].
# Saves and restores inbox + collection_items state so subsequent tests are unaffected.
test_command_output "Reflect - mark ground complete updates badge" \
  "sqlite3 \$LBPLAN_DB_PATH 'CREATE TABLE _bk_inbox AS SELECT * FROM inbox; CREATE TABLE _bk_pending AS SELECT id FROM collection_items WHERE status != \"Done\"; DELETE FROM inbox; UPDATE collection_items SET status = \"Done\" WHERE id IN (SELECT id FROM _bk_pending);' && printf 'g\nm\n\nq\n' | ./plan.sh --noprompt reflect; sqlite3 \$LBPLAN_DB_PATH 'INSERT INTO inbox SELECT * FROM _bk_inbox; UPDATE collection_items SET status = \"Pending\" WHERE id IN (SELECT id FROM _bk_pending); DROP TABLE _bk_inbox; DROP TABLE _bk_pending;'" \
  "\[v\].*Ground"

# Invalid key on the main menu is ignored (redraws); then 'g' still works
test_command_output "Reflect - invalid key at main menu ignored" \
  "printf 'x\ng\nb\nq\n' | ./plan.sh --noprompt reflect" "═══ Ground ═══"

# Invalid key on the ground actions screen is ignored (redraws); then 'b' returns
test_command_output "Reflect - invalid key at ground menu ignored" \
  "printf 'g\nz\nb\nq\n' | ./plan.sh --noprompt reflect" "═══ Ground ═══"

# Horizon 1 drill-down: pick project #1 → detail screen renders Project header
test_command_output "Reflect - h1 drill-down shows Project header" \
  "printf '1\nl\n1\nb\nb\nb\nq\n' | ./plan.sh --noprompt reflect" "Project:"

# Horizon 2 picker label carries (Np, Ng, Nv) counts suffix
test_command_output "Reflect - h2 list label shows counts pattern" \
  "printf '2\nl\nb\nb\nq\n' | ./plan.sh --nocolor --noprompt reflect" "Casa (.*p, .*g, .*v)"

# Horizon 2 drill-down shows Projects/Goals/Visions sections for the area
test_command_output "Reflect - h2 drill-down shows Projects section" \
  "printf '2\nl\n1\nb\nb\nb\nq\n' | ./plan.sh --noprompt reflect" "── Projects ──"
test_command_output "Reflect - h2 drill-down shows Goals section" \
  "printf '2\nl\n1\nb\nb\nb\nq\n' | ./plan.sh --noprompt reflect" "── Goals ──"
test_command_output "Reflect - h2 drill-down shows Visions section" \
  "printf '2\nl\n1\nb\nb\nb\nq\n' | ./plan.sh --noprompt reflect" "── Visions ──"

# Ground (d) opens a picker that lists collections with pending decisions
test_command_output "Reflect - ground decide picker shows header" \
  "printf 'g\nd\nb\nb\nq\n' | ./plan.sh --nocolor --noprompt reflect" "═══ Decide Collections ═══"

# Engage workflow tests
#
# Setup fixture so all dashboard sections render:
#   - one overdue task (past due_date)
#   - one pending recurring
#   - one pending habit
#   (Next Available task + pending collection items already exist from earlier tests.)
#
# With these, the deterministic 1-based item ordering is:
#   1 = overdue task     ("Tarefa atrasada")
#   2 = next-available   ("Comprar peças")
#   3 = recurring        ("Trocar filtro")
#   4 = habit            ("Alongar")
#   5 = collection item  ("Hyperion" or "Snow Crash" — randomized from Books)
./plan.sh task add 'Tarefa atrasada' --due-date '2026-01-01' >/dev/null 2>&1
./plan.sh recurring add 'Trocar filtro' --recurrence monthly >/dev/null 2>&1
./plan.sh habit add 'Alongar' --recurrence daily >/dev/null 2>&1

# Dashboard header
test_command_output "Engage - TUI dashboard header" \
  "printf 'q\n' | ./plan.sh --nocolor --noprompt engage" "\[E\] engage"

# Overdue section is shown when applicable
test_command_output "Engage - shows Overdue section" \
  "printf 'q\n' | ./plan.sh --nocolor --noprompt engage" "── Overdue ──"

# Next Available fallback section is shown when no tasks due in 3 days
test_command_output "Engage - shows Next Available fallback" \
  "printf 'q\n' | ./plan.sh --nocolor --noprompt engage" "── Next Available ──"

# Recurring section is shown
test_command_output "Engage - shows Recurring section" \
  "printf 'q\n' | ./plan.sh --nocolor --noprompt engage" "── Recurring ──"

# Habit section is shown
test_command_output "Engage - shows Habit section" \
  "printf 'q\n' | ./plan.sh --nocolor --noprompt engage" "── Habit ──"

# Collection Item section is shown
test_command_output "Engage - shows Collection Item section" \
  "printf 'q\n' | ./plan.sh --nocolor --noprompt engage" "── Collection Item ──"

# Dashboard action prompt footer
test_command_output "Engage - shows action prompt" \
  "printf 'q\n' | ./plan.sh --nocolor --noprompt engage" "Enter item"

# Items are numbered (1. appears on the overdue task)
test_command_output "Engage - numbers items" \
  "printf 'q\n' | ./plan.sh --nocolor --noprompt engage" " 1\."

# Selecting item 1 (a task) opens submenu that supports Start
test_command_output "Engage - task submenu shows Start" \
  "printf '1\nb\nq\n' | ./plan.sh --nocolor --noprompt engage" "(s) Start"

# Task submenu shows Complete
test_command_output "Engage - task submenu shows Complete" \
  "printf '1\nb\nq\n' | ./plan.sh --nocolor --noprompt engage" "(c) Complete"

# Task submenu shows Delete
test_command_output "Engage - task submenu shows Delete" \
  "printf '1\nb\nq\n' | ./plan.sh --nocolor --noprompt engage" "(d) Delete"

# Task submenu header identifies the item by type and name
test_command_output "Engage - submenu header names the item" \
  "printf '1\nb\nq\n' | ./plan.sh --nocolor --noprompt engage" "task: Tarefa atrasada"

# Invalid key at the dashboard redraws (prompt still appears)
test_command_output "Engage - invalid key at dashboard ignored" \
  "printf 'zzz\nq\n' | ./plan.sh --nocolor --noprompt engage" "Enter item"

# Invalid key inside the submenu redraws (Back option still shown)
test_command_output "Engage - invalid key in submenu ignored" \
  "printf '1\nzzz\nb\nq\n' | ./plan.sh --nocolor --noprompt engage" "Back to dashboard"

# Refresh stays on the dashboard
test_command_output "Engage - refresh stays on dashboard" \
  "printf 'r\nq\n' | ./plan.sh --nocolor --noprompt engage" "Enter item"

# Negative: recurring submenu does NOT show Start/Stop.
# Index 3 is the recurring in this fixture (see setup comment above).
log_print info "--------------------------------"
log_print info "Test: Engage - recurring submenu hides Start"
if printf '3\nb\nq\n' | ./plan.sh --nocolor --noprompt engage 2>/dev/null | grep -q "(s) Start"; then
  log_print error "Result: Start option should not appear on recurring submenu"
else
  log_print info "Result: ${color_green}OK${color_reset}"
fi
log_print info "--------------------------------"

# Regression: optional flags must not leak across consecutive *_add calls in
# the SAME shell process. This is the scenario the clarify TUI hits — a single
# shell sources all libs and calls task_add, project_add, etc. repeatedly. Any
# non-local globals holding optional-flag values would be observed by the next
# call. The assertion runs in a single bash -c so leakage is possible.
./plan.sh --nocolor --noprompt area add LeakArea >/dev/null 2>&1
./plan.sh --nocolor --noprompt project add LeakProj --area LeakArea >/dev/null 2>&1
./plan.sh --nocolor --noprompt goal add LeakGoal --area LeakArea >/dev/null 2>&1

leak_source_all_libs='
  for f in libs/utils/*.sh libs/database/*.sh libs/objects/*.sh libs/workflow/*.sh; do
    source "$f"
  done
'

log_print info "--------------------------------"
log_print info "Test: task_add optional flags do not leak within one shell"
bash -c "
  ${leak_source_all_libs}
  task_add 'LeakTaskWithFlags' --project LeakProj --due-date 2099-12-31 >/dev/null 2>&1
  task_add 'LeakTaskBare' >/dev/null 2>&1
" >/dev/null 2>&1
leak_row=$(sqlite3 "${LBPLAN_DB_PATH}" "SELECT COALESCE(project_id,''), COALESCE(due_date,''), COALESCE(start_date,'') FROM tasks WHERE name = 'LeakTaskBare';")
if [[ "${leak_row}" == "||" ]]; then
  log_print info "Result: ${color_green}OK${color_reset}"
else
  log_print error "Result: LeakTaskBare inherited values from previous call (got: ${leak_row})"
fi
log_print info "--------------------------------"

log_print info "--------------------------------"
log_print info "Test: project_add optional flags do not leak within one shell"
bash -c "
  ${leak_source_all_libs}
  project_add 'LeakProjWithGoal' --area LeakArea --goal LeakGoal --due-date 2099-12-31 >/dev/null 2>&1
  project_add 'LeakProjBare' --area LeakArea >/dev/null 2>&1
" >/dev/null 2>&1
leak_row=$(sqlite3 "${LBPLAN_DB_PATH}" "SELECT COALESCE(goal_id,''), COALESCE(due_date,''), COALESCE(start_date,'') FROM projects WHERE name = 'LeakProjBare';")
if [[ "${leak_row}" == "||" ]]; then
  log_print info "Result: ${color_green}OK${color_reset}"
else
  log_print error "Result: LeakProjBare inherited values from previous call (got: ${leak_row})"
fi
log_print info "--------------------------------"

# ========================================================================
# Database migrations
# ========================================================================

# Invariant: database_expected_schema default in database.sh must equal the
# db_schema value seeded in database_init.sql.
expected_in_sh=$(grep '^database_expected_schema=' libs/database/database.sh | sed 's/.*:-\([0-9]*\)}.*/\1/')
seed_in_sql=$(grep 'INSERT INTO meta VALUES ("db_schema"' libs/database/database_init.sql | sed 's/.*"\([0-9]*\)".*/\1/')
log_print info "--------------------------------"
log_print info "Test: database_expected_schema matches init.sql seed"
if [[ "${expected_in_sh}" == "${seed_in_sql}" ]]; then
  log_print info "Result: ${color_green}OK${color_reset}"
else
  log_print error "Result: database.sh has v${expected_in_sh}, init.sql seeds v${seed_in_sql}"
fi
log_print info "--------------------------------"

# Setup: isolated migrations dir so we don't pollute libs/database/migrations
test_migrations_dir="/tmp/lbplan-test-migrations"
rm -rf "${test_migrations_dir}" && mkdir -p "${test_migrations_dir}"

# Test: fresh DB (current test DB is at v5) reports up-to-date
test_command_output "Migrate status - fresh DB is up to date" \
  "./plan.sh --nocolor --noprompt migrate status" "Up to date"

# Test: downgrade (DB newer than CLI) aborts with clear error
sqlite3 "${LBPLAN_DB_PATH}" "UPDATE meta SET value='99' WHERE name='db_schema';"
test_command_output "Migrate - aborts when DB ahead of CLI" \
  "./plan.sh --nocolor --noprompt migrate status 2>&1" "is newer than this CLI supports"
# Reset for subsequent tests
sqlite3 "${LBPLAN_DB_PATH}" "UPDATE meta SET value='5' WHERE name='db_schema';"

# Test: runner applies a pending migration (auto-migrate during startup)
cat > "${test_migrations_dir}/006_test_add_column.sql" <<'EOF'
ALTER TABLE areas ADD COLUMN migration_test_flag TEXT DEFAULT 'ok';
EOF
sqlite3 "${LBPLAN_DB_PATH}" "UPDATE meta SET value='5' WHERE name='db_schema';"
test_command_output "Migrate up - applies pending migration" \
  "LBPLAN_MIGRATIONS_DIR=${test_migrations_dir} LBPLAN_EXPECTED_SCHEMA=6 ./plan.sh --nocolor --noprompt migrate up 2>&1" \
  "Applied migration 6"

# Verify meta was bumped
result=$(sqlite3 "${LBPLAN_DB_PATH}" "SELECT value FROM meta WHERE name='db_schema';")
log_print info "Test: meta.db_schema bumped after migration"
if [[ "${result}" == "6" ]]; then
  log_print info "Result: ${color_green}OK${color_reset}"
else
  log_print error "Result: meta.db_schema should be 6, got ${result}"
fi
log_print info "--------------------------------"

# Verify the ALTER actually ran
col=$(sqlite3 "${LBPLAN_DB_PATH}" "SELECT migration_test_flag FROM areas LIMIT 1;")
log_print info "Test: migration SQL actually ran"
if [[ "${col}" == "ok" ]]; then
  log_print info "Result: ${color_green}OK${color_reset}"
else
  log_print error "Result: migration column not found or wrong value: '${col}'"
fi
log_print info "--------------------------------"

# Test: failed migration rolls back (bad SQL leaves schema unchanged).
# 006 was applied in the prior test, so after a failed 007 the version must
# remain at 6 (not 7), proving the transaction rolled back cleanly.
cat > "${test_migrations_dir}/007_bad.sql" <<'EOF'
ALTER TABLE nonexistent_table ADD COLUMN x TEXT;
EOF
LBPLAN_MIGRATIONS_DIR=${test_migrations_dir} LBPLAN_EXPECTED_SCHEMA=7 \
  ./plan.sh --nocolor --noprompt migrate up >/dev/null 2>&1
result=$(sqlite3 "${LBPLAN_DB_PATH}" "SELECT value FROM meta WHERE name='db_schema';")
log_print info "Test: failed migration does not bump version"
if [[ "${result}" == "6" ]]; then
  log_print info "Result: ${color_green}OK${color_reset}"
else
  log_print error "Result: version should be 6 after failed 007, got ${result}"
fi
log_print info "--------------------------------"

# Cleanup: remove test migrations dir and reset schema so the suite's final
# state is consistent (no stray test migration column / no mismatched version).
rm -rf "${test_migrations_dir}"
sqlite3 "${LBPLAN_DB_PATH}" "UPDATE meta SET value='5' WHERE name='db_schema';"

# End
log_print info "End of test scenarios - ${color_bold}${color_green}All Passed${color_reset}"
