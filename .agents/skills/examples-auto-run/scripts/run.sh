#!/usr/bin/env bash
# examples-auto-run/scripts/run.sh
# Discovers and runs all examples in the repository, reporting pass/fail status.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
EXAMPLES_DIR="${REPO_ROOT}/examples"
RESULTS_DIR="${REPO_ROOT}/.agents/skills/examples-auto-run/results"
TIMEOUT_SECONDS=${TIMEOUT_SECONDS:-60}
PYTHON=${PYTHON:-python3}

PASSED=0
FAILED=0
SKIPPED=0
FAILED_EXAMPLES=()

mkdir -p "${RESULTS_DIR}"

log() {
  echo "[examples-auto-run] $*"
}

check_dependencies() {
  if ! command -v "${PYTHON}" &>/dev/null; then
    echo "ERROR: Python interpreter '${PYTHON}' not found." >&2
    exit 1
  fi

  if ! "${PYTHON}" -c "import openai_agents" &>/dev/null 2>&1; then
    log "Installing package in editable mode..."
    "${PYTHON}" -m pip install -e "${REPO_ROOT}" --quiet
  fi
}

run_example() {
  local example_file="$1"
  local relative_path="${example_file#${REPO_ROOT}/}"
  local example_name
  example_name=$(basename "${example_file}" .py)

  # Skip examples marked with # skip-auto-run
  if grep -q 'skip-auto-run' "${example_file}" 2>/dev/null; then
    log "SKIP  ${relative_path}  (marked skip-auto-run)"
    ((SKIPPED++)) || true
    return 0
  fi

  log "RUN   ${relative_path}"

  local log_file="${RESULTS_DIR}/${example_name}.log"

  set +e
  timeout "${TIMEOUT_SECONDS}" "${PYTHON}" "${example_file}" \
    > "${log_file}" 2>&1
  local exit_code=$?
  set -e

  if [[ ${exit_code} -eq 0 ]]; then
    log "PASS  ${relative_path}"
    ((PASSED++)) || true
  elif [[ ${exit_code} -eq 124 ]]; then
    log "FAIL  ${relative_path}  (timed out after ${TIMEOUT_SECONDS}s)"
    ((FAILED++)) || true
    FAILED_EXAMPLES+=("${relative_path} [timeout]")
  else
    log "FAIL  ${relative_path}  (exit code ${exit_code})"
    ((FAILED++)) || true
    FAILED_EXAMPLES+=("${relative_path} [exit ${exit_code}]")
  fi
}

generate_report() {
  local report_file="${RESULTS_DIR}/summary.md"
  {
    echo "# Examples Auto-Run Report"
    echo ""
    echo "Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo ""
    echo "| Result  | Count |"
    echo "|---------|-------|"
    echo "| Passed  | ${PASSED} |"
    echo "| Failed  | ${FAILED} |"
    echo "| Skipped | ${SKIPPED} |"
    echo ""
    if [[ ${#FAILED_EXAMPLES[@]} -gt 0 ]]; then
      echo "## Failed Examples"
      echo ""
      for ex in "${FAILED_EXAMPLES[@]}"; do
        echo "- ${ex}"
      done
    fi
  } > "${report_file}"
  log "Report written to ${report_file}"
}

main() {
  log "Starting examples auto-run (timeout=${TIMEOUT_SECONDS}s)"
  check_dependencies

  if [[ ! -d "${EXAMPLES_DIR}" ]]; then
    log "No examples directory found at ${EXAMPLES_DIR}, nothing to run."
    exit 0
  fi

  # Find all top-level example entry points (files named main.py or matching *_example.py)
  while IFS= read -r -d '' example_file; do
    run_example "${example_file}"
  done < <(find "${EXAMPLES_DIR}" -maxdepth 2 \
    \( -name 'main.py' -o -name '*_example.py' -o -name 'run.py' \) \
    -print0 | sort -z)

  generate_report

  log "Done. Passed=${PASSED} Failed=${FAILED} Skipped=${SKIPPED}"

  if [[ ${FAILED} -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
