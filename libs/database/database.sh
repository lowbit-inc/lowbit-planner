#!/bin/bash

##############
# Properties #
##############

database_dir="${HOME}/.lowbit-planner"
database_file="plan.db"
database_path="${LBPLAN_DB_PATH:-${database_dir}/${database_file}}"

# Expected schema version — the DB version this CLI build knows how to handle.
# When adding a migration, bump this default AND the seed in database_init.sql
# AND add the NNN_<desc>.sql file under libs/database/migrations/.
# LBPLAN_EXPECTED_SCHEMA is an env override used only by unit tests.
database_expected_schema="${LBPLAN_EXPECTED_SCHEMA:-8}"

# Migrations directory. LBPLAN_MIGRATIONS_DIR override is used only by unit
# tests so they can plant fake migrations in /tmp without touching the real dir.
database_migrations_dir="${LBPLAN_MIGRATIONS_DIR:-${SCRIPT_DIR}/libs/database/migrations}"

###########
# Methods #
###########

function database_check(){
  if [[ ! -f "${database_path}" ]] ; then
    log_print info "Database file not found. Initializing..."
    database_init
  fi
  database_migrate
}

function database_init(){
  mkdir -p "${database_dir}"
  sqlite3 "${database_path}" < ${SCRIPT_DIR}/libs/database/database_init.sql
}

function database_run(){
  this_mode="$1" ; shift  # First arg
  this_query="$@"         # All the rest

  if [[ "${this_mode}" == "box" ]]; then
    this_term_width="${COLUMNS:-0}"
    if [[ $this_term_width -eq 0 ]]; then
      this_term_width=$(stty size </dev/tty 2>/dev/null | cut -d' ' -f2)
      [[ -z "${this_term_width}" ]] && this_term_width=0
    fi
    if [[ $this_term_width -gt 0 && $this_term_width -lt $config_min_terminal_width ]]; then
      sqlite3 "--line" "${database_path}" "${this_query}" | grep -v '=\s*$'
      return ${PIPESTATUS[0]}
    fi
  fi

  sqlite3 "--${this_mode}" "${database_path}" "${this_query}" ; sqlite3_rc=$?
  return $sqlite3_rc
}

function database_get_current_schema() {
  local v
  v=$(sqlite3 "${database_path}" "SELECT value FROM meta WHERE name='db_schema';" 2>/dev/null)
  if [[ -z "${v}" ]]; then
    echo "0"
  else
    echo "${v}"
  fi
}

function database_list_pending_migrations() {
  # Lists paths of migrations with NNN prefix where current < NNN <= expected,
  # in ascending numeric order. One path per line.
  local current="$1"
  local expected="$2"
  [[ -d "${database_migrations_dir}" ]] || return 0

  local f base num
  for f in $(ls "${database_migrations_dir}"/*.sql 2>/dev/null | sort); do
    base=$(basename "${f}")
    num=$(echo "${base}" | sed 's/^0*//;s/_.*//;s/\.sql$//')
    # Skip files whose prefix is not a pure integer
    [[ "${num}" =~ ^[0-9]+$ ]] || continue
    if [[ "${num}" -gt "${current}" && "${num}" -le "${expected}" ]]; then
      echo "${f}"
    fi
  done
}

function database_apply_migration() {
  local migration_file="$1"
  local target_version="$2"
  local base
  base=$(basename "${migration_file}")

  log_print debug "Applying migration ${base} (target v${target_version})"

  # -bail makes sqlite3 abort the session on the first error. Combined with
  # the BEGIN (without a matching COMMIT, because -bail kills the session
  # before reaching it), any failing statement inside the migration leaves
  # the transaction uncommitted — SQLite rolls it back when the connection
  # closes. The meta.db_schema bump is the last statement before COMMIT, so
  # it only lands if every migration statement succeeded.
  sqlite3 -bail "${database_path}" <<SQL
BEGIN;
.read ${migration_file}
UPDATE meta SET value = '${target_version}' WHERE name = 'db_schema';
COMMIT;
SQL
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    log_print error "Failed to apply migration ${base} (rc=${rc}). Database left at v$(database_get_current_schema)."
  fi
  log_print info "Applied migration ${target_version}: ${base}"
}

function database_migrate() {
  local current expected
  current=$(database_get_current_schema)
  expected="${database_expected_schema}"

  if [[ "${current}" -gt "${expected}" ]]; then
    log_print error "Database schema (v${current}) is newer than this CLI supports (v${expected}). Please upgrade the CLI."
  fi

  if [[ "${current}" -eq "${expected}" ]]; then
    log_print debug "Database schema up to date (v${current})"
    return 0
  fi

  log_print info "Migrating database from v${current} to v${expected}..."
  local migration_file target
  for migration_file in $(database_list_pending_migrations "${current}" "${expected}"); do
    target=$(basename "${migration_file}" | sed 's/^0*//;s/_.*//;s/\.sql$//')
    database_apply_migration "${migration_file}" "${target}"
  done
  log_print info "Database migrated to v${expected}"
}

function database_migrate_main() {
  local sub="${1:-status}"
  local current expected f
  case "${sub}" in
    "status")
      current=$(database_get_current_schema)
      expected="${database_expected_schema}"
      printf "  Current schema: v%s\n" "${current}"
      printf "  Expected schema: v%s\n" "${expected}"
      if [[ "${current}" -lt "${expected}" ]]; then
        printf "  Pending migrations:\n"
        for f in $(database_list_pending_migrations "${current}" "${expected}"); do
          printf "    - %s\n" "$(basename "${f}")"
        done
      elif [[ "${current}" -gt "${expected}" ]]; then
        printf "  ${color_red}Database ahead of CLI — upgrade CLI.${color_reset}\n"
      else
        printf "  ${color_green}Up to date.${color_reset}\n"
      fi
      ;;
    "up")
      database_migrate
      ;;
    "help"|"-h"|"--help")
      help_get_message migrate
      ;;
    *)
      help_get_message migrate
      ;;
  esac
}

##########
# Script #
##########

database_check
