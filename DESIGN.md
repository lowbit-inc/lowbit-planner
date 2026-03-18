# System

## Global Commands

- [X] help
- [-] install
- [-] search
- [ ] version

## Global Args

- [ ] debug
- [ ] nocolor
- [ ] noprompt

# Objects

## Ground

### Inbox

#### Properties

- [ ] created_at
- [X] id
- [X] name

#### Methods

- [ ] add
- [ ] clarify
- [ ] delete
- [ ] list

### Task (Next Action)

#### Properties

- [ ] completed_at
- [ ] created_at
- [ ] due_date
- [ ] id
- [ ] name
- [ ] project
- [ ] start_date
- [ ] status

#### Methods

- [ ] add
- [ ] complete
- [ ] delete
- [ ] edit
- [ ] list
- [ ] search
- [ ] start
- [ ] stop

### Recurring

#### Properties

- [ ] completed_at
- [ ] created_at
- [ ] due_date
- [ ] id
- [ ] name
- [ ] recurrence
- [ ] status

#### Methods

- [ ] add
- [ ] complete
- [ ] delete
- [ ] edit
- [ ] list
- [ ] search

### Habit

#### Properties

- [ ] completed_at
- [ ] created_at
- [ ] id
- [ ] name
- [ ] recurring
- [ ] status

#### Methods

- [ ] add
- [ ] complete
- [ ] delete
- [ ] edit
- [ ] list
- [ ] search

### Collection

#### Properties

- [ ] collection
- [ ] created_at
- [ ] id
- [ ] name

#### Methods

- [ ] add
- [ ] decide
- [ ] delete
- [ ] edit
- [ ] list
- [ ] search

### Collection Item

#### Properties

- [ ] completed_at
- [ ] created_at
- [ ] id
- [ ] name
- [ ] ranking
- [ ] status

#### Methods

- [ ] add
- [ ] complete
- [ ] delete
- [ ] edit
- [ ] list
- [ ] search
- [ ] start
- [ ] stop

## Horizon 1

### Project

#### Properties

- [ ] area
- [ ] completed_at
- [ ] created_at
- [ ] due_date
- [ ] goal
- [ ] id
- [ ] name
- [ ] ranking
- [ ] start_date
- [ ] status

#### Methods

- [ ] add
- [ ] complete
- [ ] decide
- [ ] delete
- [ ] edit
- [ ] list
- [ ] search
- [ ] start
- [ ] stop

## Horizon 2

### Area

#### Properties

- [ ] id
- [ ] name

#### Methods

- [ ] add
- [ ] delete
- [ ] edit
- [ ] list

## Horizon 3

### Goal

#### Properties

- [ ] completed_at
- [ ] created_at
- [ ] due_date
- [ ] id
- [ ] name
- [ ] ranking
- [ ] start_date
- [ ] status
- [ ] vision

#### Methods

- [ ] add
- [ ] complete
- [ ] decide
- [ ] delete
- [ ] edit
- [ ] list
- [ ] search
- [ ] start
- [ ] stop

## Horizon 4

### Vision

#### Properties

- [ ] completed_at
- [ ] created_at
- [ ] id
- [ ] name
- [ ] ranking
- [ ] status

#### Methods

- [ ] add
- [ ] complete
- [ ] decide
- [ ] delete
- [ ] edit
- [ ] list
- [ ] search
- [ ] start
- [ ] stop

## Horizon 5

### Purpose

#### Properties

- [ ] created_at
- [ ] id
- [ ] name

#### Methods

- [ ] add
- [ ] edit
- [ ] delete
- [ ] list
- [ ] search

### Principle

#### Properties

- [ ] created_at
- [ ] id
- [ ] name

#### Methods

- [ ] add
- [ ] edit
- [ ] delete
- [ ] list
- [ ] search

# Phases

## Capture

- [ ] inbox add

## Clarify

- [ ] TUI
- [ ] Loop through inbox
- [ ] Choose object type
- [ ] Choose properties
- [ ] Global properties: name
- [ ] Global options: clarify | skip | abort

## Organize

- [ ] TUI
- [ ] Choose horizon
- [ ] Choose object type
- [ ] List objects

## Reflect

- [ ] TUI
- [ ] Revision status
- [ ] Choose horizon
- [ ] Ground review (inbox, task, recurring, habit, collection, collection item) (clarify)
- [ ] Horizon 1 review (project) (decide projects, next actions per project)
- [ ] Horizon 2 review (area) (projects, goals and vision per area)
- [ ] Horizon 3 review (goal) (decide goals, projects per goal)
- [ ] Horizon 4 review (vision) (decide visions, goals per vision)
- [ ] Horizon 5 review (purpose, principle) (review)
- [ ] Mark review as done

## Engage

- [ ] short
- [ ] long
- [ ] CLI
- [ ] TUI

# Tests

## Unit Tests

# Interfaces

## Command Line Interface

```bash
plan project add "Arrumar a torneira" \
  --area Casa \
  --due-date 2026-03-31
```

## Terminal User Interface

```bash
# Lowbit Planner - v0.1.0 #
[Capture] [Clarify] [Organize] [Reflect] [Engage]

Commands: [sync] [search] [help] [quit]

---

# Lowbit Planner - v0.1.0 #
[CAPTURE] [Clarify] [Organize] [Reflect] [Engage]

Add to Inbox:

Commands: [sync] [search] [help] [quit]

---

# Lowbit Planner - v0.1.0 #
[Capture] [CLARIFY] [Organize] [Reflect] [Engage]

Inbox item: XYZ
What kind of object is it?
- (t) Task
- (r) Recurring
- (h) Habit
- (c) Collection
- (i) Collection Item
- (p) Project
- (a) Area
- (g) Goal
- (v) Vision
- (n) Principle
- (u) Purpose

Convert to task!

Name*: XYZ
Start date:
Due date:
Project:

---

# Lowbit Planner - v0.1.0 #
[Capture] [Clarify] [ORGANIZE] [Reflect] [Engage]
[GROUND] [Horizon 1] [Horizon 2] [Horizon 3] [Horizon 4] [Horizon 5]
[inbox] [TASK] [recurring] [habit] [collection]

-> Some idea I had

---

# Lowbit Planner - v0.1.0 #
[Capture] [Clarify] [Organize] [REFLECT] [Engage]

[ ] Ground
[ ] Horizon 1
[*] Horizon 2
[*] Horizon 3
[ ] Horizon 4
[*] Horizon 5

Commands: [review]
Global: [sync] [search] [help] [quit]

---

# Lowbit Planner - v0.1.0 #
Menu: [Capture] [Clarify] [Organize] [Reflect] [ENGAGE]

[ Event      ] -> Almoço (2026-03-13T12:00)
[ Task       ] -> Revisar anotações (project: Revisão, due: 2026-04-01)
[ Recurring  ] -> Fazer aula do Duolingo (daily)
[ Habit      ] -> Limpar o piso do apartamento (weekly)
[ Collection ] -> Essencialismo: A Busca Indisciplinada por Menos (livros)

Commands: [task] [recurring] [habit] [collection]
Global commands: [sync] [search] [help] [quit]
```

## Web

```
Lowbit Planner

[Plan:Do]

________________________________
Capture:
```

## iOS

```
1. Capture    - Inbox
2. Clarify    - Process
3. Organize   - Explore (Ground/Horizons)
4. Reflect    - Review
5. Engage     - Focus
```

## ipadOS

## macOS

```
Lowbit Planner

[PLAN] do

[!] Ground
[ ] Horizon 1
[ ] Horizon 2
[ ] Horizon 3
[ ] Horizon 4
[ ] Horizon 5
________________________________
Capture:
```

```
Lowbit Planner

plan [DO]

Event       :
Task        :
Recur       :
Habit       :
Collection  :

________________________________
Capture:
```

## tvOS

## watchOS

```
(Plan: Horizon 2 / Do: Today)
<Event>
<Next Action>
<Habit>
<Collection>
```