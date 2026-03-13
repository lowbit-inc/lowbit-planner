# System

## Commands

- [ ] help
- [ ] install
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
- [ ] id
- [ ] name

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

- [ ] completed_at
- [ ] created_at
- [ ] due_date
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