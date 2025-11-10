# Lowbit Planner

## About

A *GTD-based* tool to use without leaving your terminal.

## Features

### GTD

#### Objects

##### Ground

- [X] Inbox
- [X] Tasks
- [X] Recurring Tasks
- [X] Habits
- [X] Collections

##### Horizon 1

- [X] Projects

##### Horizon 2

- [X] Areas

##### Horizon 3

- [X] Goals

##### Horizon 4

- [X] Vision

##### Horizon 5

- [ ] Purpose
- [ ] Principles

#### Modes

- [X] Capture (*Inbox*)
- [ ] Plan (*Review*)
- [ ] Do (*Next Actions*)

## Interfaces

- [X] **CLI** (Command Line Interface)
- [ ] **TUI** (Terminal User Interface)
- [ ] **GUI** (Graphical User Interface)

## Commands Map

- [ ] area
  - [ ] add
  - [ ] delete
  - [ ] help
  - [ ] list
  - [ ] rename
- [ ] capture
- [ ] clarify
- [ ] collection
  - [ ] add
  - [ ] add-item
  - [ ] complete
  - [ ] decide
  - [ ] delete
  - [ ] delete-item
  - [ ] forget
  - [ ] help
  - [ ] list
  - [ ] list-item
  - [ ] rename
  - [ ] rename-item
  - [ ] start
  - [ ] stop
- [ ] engage
- [ ] goal
  - [ ] add
  - [ ] delete
  - [ ] help
  - [ ] list
  - [ ] rename
- [ ] habit
  - [ ] add
  - [ ] complete
  - [ ] delete
  - [ ] help
  - [ ] list
  - [ ] rename
  - [ ] update
- [ ] help
- [ ] inbox
  - [ ] add
  - [ ] clarify
  - [ ] delete
  - [ ] help
  - [ ] list
- [ ] install
- [ ] organize
- [ ] project
  - [ ] add
  - [ ] decide
  - [ ] delete
  - [ ] help
  - [ ] list
  - [ ] list-tasks
  - [ ] list-completed
  - [ ] rename
  - [ ] start
  - [ ] stop
- [ ] principle
  - [ ] edit
  - [ ] help
  - [ ] view
- [ ] purpose
  - [ ] edit
  - [ ] help
  - [ ] view
- [ ] recurring
  - [ ] add
  - [ ] complete
  - [ ] delete
  - [ ] help
  - [ ] list
  - [ ] rename
  - [ ] update
- [ ] reflect
- [ ] task
  - [ ] add
  - [ ] complete
  - [ ] delete
  - [ ] help
  - [ ] list
  - [ ] list-completed
  - [ ] rename
  - [ ] set-deadline
  - [ ] set-project
  - [ ] start
  - [ ] stop
- [ ] version
- [ ] vision
  - [ ] add
  - [ ] delete
  - [ ] help
  - [ ] list
  - [ ] rename

## Other

- [ ] Other
  - [ ] Colors!
  - [ ] Global search
  - [ ] Confirmation upon intrusive commands (little function)
  - [ ] Installer (install command)
  - [ ] Don't decide on completed items
- [ ] TUI
  - [ ] Modes
    - [ ] Plan
    - [ ] Do
- [ ] GUI (?)
- [ ] Web (?)
- [ ] Mobile (?)
- [ ] Backend/Sync (?)

## Concept

### TUI

**Plan**:
```ascii
+-----------------------------------+
| Lowbit Planner        [PLAN] [do] |
+-----------------------------------+
| Ground    | Daily     | [Pending] |
| Horizon 1 | Weekly    | [Pending] |
| Horizon 2 | Monthly   | [  OK!  ] |
| Horizon 3 | Quarterly | [Pending] |
| Horizon 4 | Biannual  | [  OK!  ] |
| Horizon 5 | Yearly    | [Pending] |
+-----------+-----------+-----------+
| > ............................... |
+-----------------------------------+
```

**Do**:
```ascii
+------------------------------------------------------------------------------------------------------------+
| Lowbit Planner                                                                                 [plan] [DO] |
+------------------------------------------------------------------------------------------------------------+
| Type            | Description               | Deadline         | Recurrence | Parent             | State   |
+-----------------+---------------------------+------------------+------------+--------------------+---------+
| Event           | English Class             | 2025-11-02 15:00 | --         | --                 | --      |
| Task            | Choose travel destination | 2025-11-05       | --         | Vacation (Project) | Pending |
| Recurrent Task  | Pay the bills             | (This month)     | Monthly    | --                 | Pending |
| Habit           | Drink water               | (Today)          | Daily      | --                 | Pending |
| Collection Item | Persona 5: Royal          | Started          | --         | Games (Collection) | Started |
+------------------------------------------------------------------------------------------------------------+
| > ........................................................................................................ |
+------------------------------------------------------------------------------------------------------------+
```
