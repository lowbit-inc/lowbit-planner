# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all unit tests (must run from repo root)
./tests/unit-tests.sh

# Run the tool directly (before install)
./plan.sh <command>

# Install the CLI to PATH
./plan.sh install

# Enable debug output
./plan.sh --debug <command>

# Skip user confirmation prompts (useful in scripts/tests)
LBPLAN_NOPROMPT=true ./plan.sh <command>

# Use an isolated database (used by unit tests automatically)
LBPLAN_DB_PATH=/tmp/custom.db ./plan.sh <command>
```

There is no linter configured.

## Cross-platform compatibility

The project must run on both **macOS** (BSD toolchain) and **Linux** (GNU toolchain). Keep these rules in mind when making changes:

- **SQL string literals** must always use single quotes (`'value'`). Double quotes are identifier delimiters in standard SQLite; Linux enforces this strictly (`SQLITE_DQS=0`), macOS is lenient.
- **`date` command** differs between BSD (macOS) and GNU (Linux). All date arithmetic goes through helpers in `libs/utils/datetime.sh`, which detects the flavor at source time. Do not call `date` directly with platform-specific flags outside that file.
- **`readlink`/`realpath`** — `plan.sh` already handles this with `readlink -f ... || realpath ...` fallback. Follow the same pattern if you need to resolve paths elsewhere.

## Architecture

`plan.sh` is the single entry point. It sources all libraries, parses global flags (`--debug`, `--nocolor`, `--noprompt`), then dispatches to object or workflow handler functions.

### Library layers (sourced in order by `plan.sh`)

- `libs/utils/` — stateless helpers: colors, logging, datetime, validation, config, test framework
- `libs/database/` — SQLite abstraction (`database_run <mode> <query>`) and schema (`database_init.sql`)
- `libs/objects/` — one file per GTD object; each exposes a `<object>_main "$@"` dispatcher
- `libs/workflow/` — the five GTD phases (capture, clarify, organize, reflect, engage) plus decision/ranking

### GTD object hierarchy

```
Ground:    inbox, task, recurring, habit, collection, item
Horizon 1: project  (belongs to area)
Horizon 2: area
Horizon 3: goal     (belongs to area, optionally vision)
Horizon 4: vision   (belongs to area)
Horizon 5: purpose, principle
```

Foreign key chain: `task → project → area`, `goal → vision → area`.

### Adding a new object command

Each object file follows the same pattern:

1. Define `<object>_add()`, `<object>_list()`, etc. using the shared helpers from `generic.sh`.
2. Define `<object>_main()` with a `case` statement dispatching sub-commands.
3. Register `<object>_main "$@"` in the `case` block at the bottom of `plan.sh`.
4. Add the corresponding SQL table and `*_view` to `database_init.sql`.

### Key conventions

- **`generic.sh`** provides reusable CRUD: `generic_add`, `generic_delete`, `generic_list`, `generic_complete`, `generic_set_property`, `generic_set_status`. Prefer these over raw `database_run` calls.
- **Database reads for display** always query the `*_view` (e.g. `inbox_view`, `tasks_view`), not the raw table.
- **`log_print error`** calls `exit 1` — it is not a pure logging call.
- **`log_print user`** pauses and waits for ENTER unless `LBPLAN_NOPROMPT=true` is set.
- **Status values** are the strings `Pending`, `In Progress`, `Done`.
- **Dates** use ISO format `YYYY-MM-DD`; timestamps use `YYYY-MM-DD HH:MM:SS`.
- **`LBPLAN_DB_PATH`** overrides the default database location (`~/.lowbit-planner/plan.db`). The unit test suite sets this to `/tmp/lowbit-planner-unit-tests.db` and resets it on each run.

### Adding a schema migration

When you need to evolve the schema, three things must change together:

1. Add a new file at `libs/database/migrations/NNN_<snake_case_desc>.sql` where `NNN` is the next integer (zero-padded to 3 digits), with the SQL statements for the change. No `BEGIN`/`COMMIT` — the runner wraps each migration in its own transaction.
2. Edit `libs/database/database_init.sql` inline to reflect the new schema as the baseline for fresh installs, and bump `INSERT INTO meta VALUES ('db_schema', 'NNN')` to match. **Always use single quotes for string literals in SQL** — double quotes are identifier delimiters in standard SQLite (Linux enforces this strictly; macOS is lenient).
3. Bump the default in `database_expected_schema="${LBPLAN_EXPECTED_SCHEMA:-NNN}"` in `libs/database/database.sh`.

The three must agree. A unit test enforces this. Every invocation of `./plan.sh` auto-applies pending migrations before dispatching; `./plan.sh migrate status` and `./plan.sh migrate up` let you inspect or force the process manually.

### Test framework

Tests live in `tests/unit-tests.sh` and use `test_command_output "<title>" "<shell command>" "<expected substring>"` from `libs/utils/test.sh`. Each test runs the command and greps stdout for the expected string.
