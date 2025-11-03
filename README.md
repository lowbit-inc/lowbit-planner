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
- [ ] References

##### Horizon 1

- [X] Projects

##### Horizon 2

- [X] Areas

##### Horizon 3

- [ ] Goals

##### Horizon 4

- [ ] Vision

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

## TODO

- [X] CLI
  - [X] Objects
    - [X] Ground
      - [X] Inbox
        - [X] add
        - [X] delete
        - [X] list
      - [X] Tasks
        - [X] add
        - [X] complete
        - [X] delete
        - [X] edit
        - [X] list
        - [X] rename
        - [X] start
        - [X] stop
      - [X] Recurring Tasks
        - [X] add
        - [X] complete
        - [X] delete
        - [ ] edit
        - [X] list
      - [X] Habits
        - [X] add
        - [X] complete
        - [X] delete
        - [ ] edit
        - [X] list
      - [X] Collections
        - [X] add
        - [X] delete
        - [X] list
        - [X] rename
      - [X] Collection Items
        - [X] add
        - [X] complete
        - [ ] decide
        - [X] delete
        - [ ] edit
        - [X] list
        - [X] start
        - [X] stop
    - [ ] Horizon 1
      - [ ] Projects
         - [X] add
         - [ ] complete
         - [ ] decide
         - [X] delete
         - [ ] edit
         - [ ] list (show amount of tasks)
         - [ ] list-tasks
         - [ ] note
         - [X] rename
         - [ ] start
         - [ ] stop
    - [X] Horizon 2
      - [X] Areas
        - [X] add
        - [X] delete
        - [X] list
        - [ ] note
        - [X] rename
    - [ ] Horizon 3
      - [ ] Goals
        - [ ] add
        - [ ] complete
        - [ ] decide
        - [ ] delete
        - [ ] edit
        - [ ] list
        - [ ] note
        - [ ] start
        - [ ] stop
    - [ ] Horizon 4
      - [ ] Vision
        - [ ] add
        - [ ] decide
        - [ ] delete
        - [ ] edit
        - [ ] list
        - [ ] note
    - [ ] Horizon 5
      - [ ] Purpose
        - [ ] note
      - [ ] Principles
        - [ ] note
  - [X] Actions
    - [X] Capture (Inbox)
    - [ ] Clarify
    - [ ] Organize
    - [ ] Reflect (Review)
    - [ ] Engage (Next Actions / Do)
  - [ ] Other
    - [ ] Colors!
    - [ ] Global search
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
