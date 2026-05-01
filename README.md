# Lowbit Planner

A GTD-inspired life planner that lives in your terminal. Single Bash script,
SQLite under the hood, no daemons, no cloud, no lock-in.

```
$ plan engage

  ═══ Overdue ═══
     1. Pagar IPVA            [ip] (project: Casa, due 2026-04-20)
     2. Renovar passaporte         (due 2026-04-22)

  ═══ Recurring ═══
     3. Backup mensal              (monthly)

  ═══ Habit ═══
     4. Meditar 10 min             (daily)

  Pick a number to act on it, (r) refresh, (q) quit:
```

## TL;DR

- **What it is**: a CLI that walks you through the five GTD phases — Capture,
  Clarify, Organize, Reflect, Engage — across the six GTD horizons (Ground →
  Purpose).
- **What it gives you**: an inbox you can dump anything into, a guided flow
  to turn that into tasks/projects/goals/etc., and a single `engage` screen
  that tells you what to work on right now.
- **What it doesn't**: sync, notify, render Markdown, or pretend to be Notion.
  It's one local SQLite file you own.
- **Why Bash + SQLite**: zero runtime dependencies beyond what your shell
  already has. Install is a `cp` to `/usr/local/bin`.

## Install

```bash
git clone git@github.com:lowbit-inc/lowbit-planner.git
cd lowbit-planner
./plan.sh install        # symlinks `plan` into /usr/local/bin
plan version
```

Requires `bash`, `sqlite3`, and a UTF-8 capable terminal. Database lives at
`~/.lowbit-planner/plan.db` — back that file up and you've backed up
everything.

## Quick Start

The five workflows are the whole product. You can ignore the object-level
commands (`task add`, `project add`, ...) and just live inside them.

### 1. Capture — empty your head

```bash
plan capture "Renovar passaporte"
plan capture "Ideia: refatorar o pipeline de deploy"
plan capture                       # opens TUI to add many at once
```

Everything goes into the inbox unprocessed. The point is to be fast.

### 2. Clarify — turn inbox items into something actionable

```bash
plan clarify
```

Walks each inbox item through "what is this?" — task, project, goal, habit,
collection, reference material, trash. Picks the right object, fills in the
fields, deletes from the inbox. Nothing leaves the inbox without a decision.

### 3. Organize — see and rank what you have

```bash
plan organize             # interactive explorer across all horizons
plan organize ground      # jump straight to the Ground level
plan organize horizon1    # projects
```

Inside, you can re-order items by priority (the `position` field), edit
properties, and drill from a project into its tasks.

### 4. Reflect — the weekly/monthly review, guided

```bash
plan reflect
```

Picks a horizon (Ground daily, Projects weekly, Areas monthly, Goals
quarterly, Visions biannual, Purposes/Principles yearly) and walks you
through the checks that horizon needs — decide what's still alive, validate
what still resonates, mark the review done.

### 5. Engage — what now?

```bash
plan engage
```

The dashboard. Overdue tasks, due today, due in 3 days, plus your recurring
and habit of the day, plus one item from a collection. Pick a number to
start/complete/delete it. If nothing is urgent, a "Next Actions" section
suggests one project task and one orphan task to keep you moving.

### Object commands (the escape hatch)

When you want raw CRUD without a workflow:

```bash
plan task add "Comprar leite" --due 2026-04-30
plan project add "Reformar cozinha" --area Casa
plan task list --status "In Progress"
plan task start 12
plan task complete 12
```

Every object has the same verbs: `add`, `list`, `edit`, `delete`,
`complete`, `search`, plus `start`/`stop` where it makes sense. `plan <obj>
help` shows the exact flags.

### Useful global flags

```bash
plan --debug <cmd>       # verbose logging
plan --nocolor <cmd>     # plain output (good for piping/grepping)
plan --noprompt <cmd>    # skip "press ENTER to continue" pauses
LBPLAN_DB_PATH=/tmp/x.db plan <cmd>   # use a sandbox database
```

---

## The Nerdy Section

For people who want to know how the sausage is made before they install it.

### Mental model: GTD, taken seriously

The whole tool is built on top of David Allen's GTD with the horizons of
focus mapped to concrete object types:

| Horizon | Cadence | Objects |
|---------|---------|---------|
| Ground | Daily | inbox, task, recurring, habit, collection, item |
| H1 — Projects | Weekly | project (belongs to area) |
| H2 — Areas | Monthly | area |
| H3 — Goals | Quarterly | goal (belongs to vision) |
| H4 — Visions | Biannual | vision (belongs to area) |
| H5 — Purpose | Yearly | purpose, principle |

The five workflows (capture/clarify/organize/reflect/engage) are not
arbitrary menus — each maps 1:1 to a phase of the GTD loop, and each is a
small TUI built from the same primitives (counter + picker + action menu),
so once you've used one you've used them all.

### Architecture

```
plan.sh                 ← single entry point, sources everything,
                          parses global flags, dispatches subcommands
libs/utils/             ← stateless helpers (colors, log, datetime, test)
libs/database/          ← sqlite3 wrapper + schema + numbered migrations
libs/objects/           ← one file per object type, all built on generic.sh
libs/workflow/          ← capture, clarify, organize, reflect, engage
tests/unit-tests.sh     ← ~250 tests, run with `./tests/unit-tests.sh`
```

There is no build step, no package manager, no daemon. `./plan.sh install`
drops a symlink and that's the install. Uninstall is `rm /usr/local/bin/plan`.

### Storage

A single SQLite file at `~/.lowbit-planner/plan.db`. Every read for display
goes through a `*_view` (e.g. `tasks_view`) so the UI layer never touches
raw tables. Schema evolves through numbered migrations
(`libs/database/migrations/NNN_*.sql`); the CLI auto-applies pending ones
on every invocation, and `plan migrate status` / `plan migrate up` let you
inspect or force the process. A unit test enforces that the migration
files, the init SQL baseline, and the expected-version constant in the CLI
all agree — drift is caught at test time, not at runtime.

Want to back up? `cp ~/.lowbit-planner/plan.db somewhere`. Want to sync
across machines? Put that file in your favorite cloud-synced folder.
Want to query it? `sqlite3 ~/.lowbit-planner/plan.db`.

### Engage ranking, in detail

The Engage dashboard is the workflow with the most opinion baked in.
Section ordering inside Overdue / Due Today / Due in 3 Days is:

```sql
ORDER BY
  (due_date IS NULL OR due_date = '') ASC,   -- dated first
  due_date ASC,                              -- soonest first
  (status = 'In Progress') DESC,             -- already-started first
  position DESC,                             -- higher manual weight first
  id ASC                                     -- older tiebreaks newer
```

When all three date sections are empty, a fallback "Next Actions" section
appears with up to two items: the highest-position task in the
highest-position active project, plus the oldest orphan task (no project).
The first keeps you investing in what matters; the second keeps the
"someday I'll get to it" pile from rotting forever.

Recurring and habit are intentionally asymmetric: the recurring shown is
the oldest pending one (deterministic — it sticks until completed), the
habit is random and rotates on every refresh. That gives recurring more
weight by default while still keeping habits visible.

### Testing

```bash
./tests/unit-tests.sh
```

Runs against a throwaway database at `/tmp/lowbit-planner-unit-tests.db`.
Tests use a tiny `test_command_output "<title>" "<cmd>" "<expected
substring>"` helper — they shell out to `./plan.sh` and grep stdout. No
mocks. The whole suite runs in seconds.

### Adding things

- **New object command**: drop a `libs/objects/foo.sh` that defines
  `foo_main "$@"`, register it in the dispatcher at the bottom of
  `plan.sh`, add the table + view to `database_init.sql`. Lean on
  `generic.sh` for the CRUD verbs.
- **New schema migration**: add `libs/database/migrations/NNN_desc.sql`,
  mirror the change in `database_init.sql`, bump `db_schema` in both
  `database_init.sql` and the `database_expected_schema` constant in
  `database.sh`. The three must agree (a test enforces it).

See `CLAUDE.md` for the full contributor cheat sheet.

### Status

v1.0.0 — the GTD loop is complete end-to-end across all six horizons, all
five workflows, and the object layer underneath them. Single user, single
machine, no sync. That's the line v1 draws.
