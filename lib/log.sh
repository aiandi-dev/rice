#!/usr/bin/env bash
# rice logging utilities
# Provides consistent, semantic output formatting

# Colors (only if terminal supports them)
if [[ -t 1 ]] && [[ -n "${TERM:-}" ]] && [[ "${TERM}" != "dumb" ]]; then
  readonly LOG_RED=$'\033[0;31m'
  readonly LOG_GREEN=$'\033[0;32m'
  readonly LOG_YELLOW=$'\033[0;33m'
  readonly LOG_BLUE=$'\033[0;34m'
  readonly LOG_GRAY=$'\033[0;90m'
  readonly LOG_RESET=$'\033[0m'
else
  readonly LOG_RED=''
  readonly LOG_GREEN=''
  readonly LOG_YELLOW=''
  readonly LOG_BLUE=''
  readonly LOG_GRAY=''
  readonly LOG_RESET=''
fi

# Symbols
readonly SYM_CHECK="✓"
readonly SYM_CROSS="✗"
readonly SYM_BULLET="•"
readonly SYM_WARN="⚠"

# Phase tracking
RICE_CURRENT_PHASE=0
RICE_TOTAL_PHASES=9

# Log a phase header: [N/9] Phase Name
log_phase() {
  local name="$1"
  RICE_CURRENT_PHASE=$((RICE_CURRENT_PHASE + 1))
  printf "\n${LOG_BLUE}[%d/%d]${LOG_RESET} %s\n" "$RICE_CURRENT_PHASE" "$RICE_TOTAL_PHASES" "$name"
}

# Log a step announcement (blue bullet)
log_step() {
  local msg="$1"
  printf "  ${LOG_BLUE}${SYM_BULLET}${LOG_RESET} %s\n" "$msg"
}

# Log success (green checkmark)
# Usage: log_ok "component" ["version"] ["suffix"]
log_ok() {
  local component="$1"
  local version="${2:-}"
  local suffix="${3:-}"

  local output="  ${LOG_GREEN}${SYM_CHECK}${LOG_RESET} ${component}"

  if [[ -n "$version" && -n "$suffix" ]]; then
    output+=" (${version}, ${suffix})"
  elif [[ -n "$version" ]]; then
    output+=" (${version})"
  elif [[ -n "$suffix" ]]; then
    output+=" (${suffix})"
  fi

  printf "%s\n" "$output"
}

# Log warning (yellow)
log_warn() {
  local msg="$1"
  printf "  ${LOG_YELLOW}${SYM_WARN}${LOG_RESET} %s\n" "$msg"
}

# Log error (red cross)
log_error() {
  local msg="$1"
  printf "  ${LOG_RED}${SYM_CROSS}${LOG_RESET} %s\n" "$msg"
}

# Log detail/verbose info (gray, indented)
log_detail() {
  local msg="$1"
  if [[ "${RICE_VERBOSE:-0}" == "1" ]]; then
    printf "    ${LOG_GRAY}%s${LOG_RESET}\n" "$msg"
  fi
}

# Log "installing now" indicator
log_installing() {
  local component="$1"
  printf "  ${SYM_BULLET} %s\n" "$component"
}

# Print self-contained error with recovery steps
# Usage: log_error_box "component" "operation" "error_msg" "recovery_step1" "recovery_step2" ...
log_error_box() {
  local component="$1"
  local operation="$2"
  local error_msg="$3"
  shift 3
  local recovery_steps=("$@")

  printf "\n${LOG_RED}${SYM_CROSS} Failed: %s %s${LOG_RESET}\n\n" "$component" "$operation"
  printf "  Error: %s\n" "$error_msg"

  if [[ ${#recovery_steps[@]} -gt 0 ]]; then
    printf "\n  Try:\n"
    local i=1
    for step in "${recovery_steps[@]}"; do
      printf "    %d. %s\n" "$i" "$step"
      ((i++))
    done
  fi

  printf "\n  If this persists, report: https://github.com/pentaxis93/rice/issues\n\n"
}

# Print installation summary box
# Usage: log_summary "total_components" "elapsed_time" ["failed_count"]
log_summary() {
  local total="$1"
  local elapsed="$2"
  local failed="${3:-0}"

  printf "\n"
  if [[ "$failed" -eq 0 ]]; then
    printf "${LOG_GREEN}All %d components verified.${LOG_RESET}\n" "$total"
  else
    printf "${LOG_YELLOW}%d of %d components installed (%d failed).${LOG_RESET}\n" \
      "$((total - failed))" "$total" "$failed"
  fi
  printf "Completed in %s\n" "$elapsed"
}

# Print compact phase status for re-runs
# Usage: log_phase_compact "name" "installed" "total"
log_phase_compact() {
  local name="$1"
  local installed="$2"
  local total="$3"

  # Pad phase name to 18 chars, right-pad counts for alignment
  printf "[%d/%d] %-18s ${LOG_GREEN}${SYM_CHECK}${LOG_RESET} (%2d/%-2d installed)\n" \
    "$RICE_CURRENT_PHASE" "$RICE_TOTAL_PHASES" "$name" "$installed" "$total"
  RICE_CURRENT_PHASE=$((RICE_CURRENT_PHASE + 1))
}

# Print the rice header
log_header() {
  local version="$1"
  local first_run="${2:-false}"

  printf "rice v%s\n" "$version"
  if [[ "$first_run" == "true" ]]; then
    printf "Your terminal, seasoned.\n"
  fi
}

# Print interrupt message
log_interrupt() {
  local phase="$1"
  local tool="$2"
  local state_file="$3"

  printf "\n${LOG_YELLOW}Interrupted during [%d/%d] while installing %s${LOG_RESET}\n\n" \
    "$RICE_CURRENT_PHASE" "$RICE_TOTAL_PHASES" "$tool"
  printf "State saved: %s\n\n" "$state_file"
  printf "To resume:      rice\n"
  printf "To start fresh: rm %s && rice\n\n" "$state_file"
}

# Print resume notification
log_resume() {
  local phase="$1"
  local phase_name="$2"

  printf "${LOG_BLUE}Resuming from [%d/%d] %s...${LOG_RESET}\n" \
    "$phase" "$RICE_TOTAL_PHASES" "$phase_name"
  printf "State preserved from previous run.\n\n"
}
