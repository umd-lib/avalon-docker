#!/bin/bash
# Migrate a Fedora 4 export to Fedora 6 OCFL format.
# Runs two upgrade passes: F4 → F5 (intermediate), then F5 → F6.
#
# Environment variables:
#   BASE_URI     Fedora REST base URI used in F6 OCFL metadata
#                (default: http://fedora:8080/fedora/rest)
#   DATA_DIR     Root of the data volume              (default: /data)
#   INPUT_DIR    F4 export directory                  (default: $DATA_DIR/fcrepo4_export)
#   F5_DIR       F5 intermediate output directory     (default: $DATA_DIR/fcrepo5_export)
#   F6_DIR       F6 OCFL output directory             (default: $DATA_DIR/fcrepo6_export)
#
# Resume:
#   If a step fails mid-way, a remaining_<timestamp>.log file is written.
#   Re-run the container with the same /data volume; the script will
#   detect the remaining file for whichever step failed and resume it.

set -euo pipefail

BASE_URI="${BASE_URI:-http://fedora:8080/fcrepo/rest}"
DATA_DIR="${DATA_DIR:-/data}"
INPUT_DIR="${INPUT_DIR:-${DATA_DIR}/fcrepo4_export}"
F5_DIR="${F5_DIR:-${DATA_DIR}/fcrepo5_export}"
F6_DIR="${F6_DIR:-${DATA_DIR}/fcrepo6_export}"

TIMESTAMP=$(date +%Y%m%dT%H%M%S)

# ── Helpers ───────────────────────────────────────────────────────────────────

log() { echo "[$(date -Iseconds)] $*"; }

# Check if an output directory is non-empty (primary completion indicator).
# fcrepo-upgrade-utils exits 0 on success but prints no "complete" banner.
output_has_content() {
  local dir="$1"
  [[ -d "${dir}" ]] && [[ -n "$(ls -A "${dir}" 2>/dev/null)" ]]
}

find_remaining() {
  local prefix="$1"
  ls -t "${DATA_DIR}"/remaining_${prefix}*.log 2>/dev/null | head -1 || true
}

# Run java and capture its exit code even through the tee pipeline.
run_java() {
  local log_file="$1"
  shift
  java "$@" 2>&1 | tee "${log_file}"
  return "${PIPESTATUS[0]}"
}

# ── Validate input ────────────────────────────────────────────────────────────

if [[ ! -d "${INPUT_DIR}" ]]; then
  log "ERROR: Input directory not found: ${INPUT_DIR}" >&2
  log "       Mount the fcrepo4-export output volume at ${DATA_DIR}" >&2
  exit 1
fi

mkdir -p "${F5_DIR}" "${F6_DIR}"

log "Starting Fedora 4 → 6 migration"
log "  INPUT_DIR : ${INPUT_DIR}"
log "  F5_DIR    : ${F5_DIR}"
log "  F6_DIR    : ${F6_DIR}"
log "  BASE_URI  : ${BASE_URI}"

# ── Step 1: F4 → F5 ──────────────────────────────────────────────────────────

F5_LOG="${DATA_DIR}/upgrade_5_${TIMESTAMP}.log"
F5_DONE_MARKER="${DATA_DIR}/.f4_to_f5_complete"

if [[ -f "${F5_DONE_MARKER}" ]]; then
  log "Step 1 (F4→F5) already completed — skipping."
else
  RESUME_ARGS=()
  REMAINING=$(find_remaining "f4_to_f5")
  if [[ -n "${REMAINING}" ]]; then
    log "Step 1: Resuming from: ${REMAINING}"
    RESUME_ARGS=(--resource-info-file "${REMAINING}")
  else
    log "Step 1: Migrating Fedora 4 → Fedora 5..."
  fi

  run_java "${F5_LOG}" \
    -jar /opt/fcrepo-upgrade-utils.jar \
    --input-dir "${INPUT_DIR}" \
    --output-dir "${F5_DIR}" \
    --source-version 4.7.5 \
    --target-version 5+ \
    "${RESUME_ARGS[@]}"
  JAVA_EXIT=$?

  if [[ "${JAVA_EXIT}" -eq 0 ]] && output_has_content "${F5_DIR}"; then
    log "Step 1 (F4→F5) completed successfully."
    touch "${F5_DONE_MARKER}"
  else
    REMAINING_NEW=$(find_remaining "")
    if [[ -n "${REMAINING_NEW}" ]]; then
      log "ERROR: Step 1 did not finish. Resume file: ${REMAINING_NEW}" >&2
      # Rename so we can identify it belongs to step 1 on next run
      mv "${REMAINING_NEW}" "${DATA_DIR}/remaining_f4_to_f5_${TIMESTAMP}.log" 2>/dev/null || true
    else
      log "ERROR: Step 1 failed (exit code ${JAVA_EXIT}). Check ${F5_LOG}" >&2
    fi
    exit 1
  fi
fi

# ── Step 2: F5 → F6 ──────────────────────────────────────────────────────────

F6_LOG="${DATA_DIR}/upgrade_6_${TIMESTAMP}.log"
F6_DONE_MARKER="${DATA_DIR}/.f5_to_f6_complete"

if [[ -f "${F6_DONE_MARKER}" ]]; then
  log "Step 2 (F5→F6) already completed — skipping."
else
  RESUME_ARGS=()
  REMAINING=$(find_remaining "f5_to_f6")
  if [[ -n "${REMAINING}" ]]; then
    log "Step 2: Resuming from: ${REMAINING}"
    RESUME_ARGS=(--resource-info-file "${REMAINING}")
  else
    log "Step 2: Migrating Fedora 5 → Fedora 6..."
  fi

  run_java "${F6_LOG}" \
    --add-opens java.base/java.util.concurrent=ALL-UNNAMED \
    -jar /opt/fcrepo-upgrade-utils.jar \
    --input-dir "${F5_DIR}" \
    --output-dir "${F6_DIR}" \
    --source-version 5+ \
    --target-version 6+ \
    --base-uri "${BASE_URI}" \
    "${RESUME_ARGS[@]}"
  JAVA_EXIT=$?

  if [[ "${JAVA_EXIT}" -eq 0 ]] && output_has_content "${F6_DIR}"; then
    log "Step 2 (F5→F6) completed successfully."
    touch "${F6_DONE_MARKER}"
  else
    REMAINING_NEW=$(find_remaining "")
    if [[ -n "${REMAINING_NEW}" ]]; then
      log "ERROR: Step 2 did not finish. Resume file: ${REMAINING_NEW}" >&2
      mv "${REMAINING_NEW}" "${DATA_DIR}/remaining_f5_to_f6_${TIMESTAMP}.log" 2>/dev/null || true
    else
      log "ERROR: Step 2 failed (exit code ${JAVA_EXIT}). Check ${F6_LOG}" >&2
    fi
    exit 1
  fi
fi

log "Migration complete. Fedora 6 OCFL data is in: ${F6_DIR}"
log "Next step: sync ${F6_DIR}/data/ocfl-root to your Fedora 6 storage."
