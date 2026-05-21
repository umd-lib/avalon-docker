#!/bin/bash
# Export all content from a Fedora 4 instance.
#
# Environment variables:
#   FEDORA_URL       Fedora REST API base URL  (default: http://fedora:8080/fedora/rest)
#   FEDORA_USER      Fedora admin username     (default: fedoraAdmin)
#   FEDORA_PASSWORD  Fedora admin password     (default: fedoraAdmin)
#   EXPORT_DIR       Where to write the export (default: /data/fcrepo4_export)

set -euo pipefail

FEDORA_URL="${FEDORA_URL:-http://fedora:8080/fedora/rest}"
FEDORA_USER="${FEDORA_USER:-fedoraAdmin}"
FEDORA_PASSWORD="${FEDORA_PASSWORD:-fedoraAdmin}"
EXPORT_DIR="${EXPORT_DIR:-/data/fcrepo4_export}"
DATA_DIR="${DATA_DIR:-/data}"

TIMESTAMP=$(date +%Y%m%dT%H%M%S)
LOG_FILE="${DATA_DIR}/export_${TIMESTAMP}.log"

mkdir -p "${EXPORT_DIR}"

echo "[$(date -Iseconds)] Starting Fedora 4 export"
echo "  FEDORA_URL : ${FEDORA_URL}"
echo "  EXPORT_DIR : ${EXPORT_DIR}"
echo "  LOG_FILE   : ${LOG_FILE}"

# ── Resume support ──────────────────────────────────────────────────────────
# Per upstream docs, resuming requires --repositoryRoot + --resourcesFile
# instead of --resource. The two flags are mutually exclusive.
RESUME_ARGS=()
REMAINING=$(ls -t "${DATA_DIR}"/remaining_*.log 2>/dev/null | head -1 || true)
if [[ -n "${REMAINING}" ]]; then
  echo "[$(date -Iseconds)] Resuming from: ${REMAINING}"
  RESUME_ARGS=(--repositoryRoot "${FEDORA_URL}" --resourcesFile "${REMAINING}")
else
  RESUME_ARGS=(--resource "${FEDORA_URL}")
fi

# ── Run export ───────────────────────────────────────────────────────────────
java -jar /opt/fcrepo-import-export.jar -b \
  --dir "${EXPORT_DIR}" \
  --user "${FEDORA_USER}:${FEDORA_PASSWORD}" \
  --mode export \
  --binaries \
  --membership \
  --auditLog \
  "${RESUME_ARGS[@]}" \
  2>&1 | tee "${LOG_FILE}"

# ── Verify completion ────────────────────────────────────────────────────────
if grep -q "(Exporter) Export complete" "${LOG_FILE}"; then
  echo "[$(date -Iseconds)] Export completed successfully. Output: ${EXPORT_DIR}"
else
  REMAINING_NEW=$(ls -t "${DATA_DIR}"/remaining_*.log 2>/dev/null | head -1 || true)
  if [[ -n "${REMAINING_NEW}" ]]; then
    echo "[$(date -Iseconds)] ERROR: Export did not finish. Resume file: ${REMAINING_NEW}" >&2
    echo "  Re-run the container with the same /data volume to resume." >&2
  else
    echo "[$(date -Iseconds)] ERROR: Export may have failed. Check ${LOG_FILE}" >&2
  fi
  exit 1
fi
