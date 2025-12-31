#!/usr/bin/env bash
# rice - opinionated terminal environment installer
# https://github.com/pentaxis93/rice
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/pentaxis93/rice/main/install.sh | bash
#   ./install.sh [command]
#
# Commands:
#   (none)    Install/update rice
#   doctor    Check installation health
#   status    Show installed components
#   update    Fetch latest rice and re-run
#   help      Show this help
#   version   Show version

set -euo pipefail

# Determine script location (works for both direct run and curl|bash)
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  RICE_INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # Running from curl | bash - need to download
  RICE_INSTALL_DIR="${HOME}/.cache/rice/installer"
  mkdir -p "$RICE_INSTALL_DIR"

  if ! curl -fsSL "https://github.com/pentaxis93/rice/archive/refs/heads/main.tar.gz" | \
    tar -xz -C "$RICE_INSTALL_DIR" --strip-components=1 2>/dev/null; then
    echo "Error: Failed to download rice installer"
    exit 1
  fi
fi

# Load version
RICE_VERSION="$(cat "${RICE_INSTALL_DIR}/VERSION" 2>/dev/null || echo "dev")"
export RICE_VERSION RICE_INSTALL_DIR

# Source library files
# shellcheck source=lib/log.sh
source "${RICE_INSTALL_DIR}/lib/log.sh"
# shellcheck source=lib/detect.sh
source "${RICE_INSTALL_DIR}/lib/detect.sh"
# shellcheck source=lib/state.sh
source "${RICE_INSTALL_DIR}/lib/state.sh"
# shellcheck source=lib/versions.sh
source "${RICE_INSTALL_DIR}/lib/versions.sh"
# shellcheck source=lib/packages.sh
source "${RICE_INSTALL_DIR}/lib/packages.sh"
# shellcheck source=lib/download.sh
source "${RICE_INSTALL_DIR}/lib/download.sh"
# shellcheck source=lib/runtimes.sh
source "${RICE_INSTALL_DIR}/lib/runtimes.sh"
# shellcheck source=lib/shell.sh
source "${RICE_INSTALL_DIR}/lib/shell.sh"
# shellcheck source=lib/tools.sh
source "${RICE_INSTALL_DIR}/lib/tools.sh"
# shellcheck source=lib/config.sh
source "${RICE_INSTALL_DIR}/lib/config.sh"

# Track start time
RICE_START_TIME=$(date +%s)

# Count failures for exit code
RICE_FAILURES=0

# Interrupt handler
handle_interrupt() {
  local current_tool
  current_tool="$(state_get_current_tool 2>/dev/null || echo "unknown")"
  log_interrupt "$RICE_CURRENT_PHASE" "$current_tool" "$RICE_STATE_FILE"
  exit 130
}

# Cleanup on exit
cleanup() {
  local exit_code=$?

  # Clear current tool on clean exit
  if [[ $exit_code -eq 0 || $exit_code -eq 2 ]]; then
    state_clear_current_tool 2>/dev/null || true
  fi
}

trap handle_interrupt SIGINT SIGTERM
trap cleanup EXIT

# Print help
show_help() {
  cat << EOF
rice v${RICE_VERSION} - opinionated terminal environment installer

Usage:
  rice [command]

Commands:
  (none)    Install or update rice environment
  doctor    Check installation health
  status    Show installed components
  update    Fetch latest rice and re-run
  help      Show this help
  version   Show version

Environment variables:
  RICE_YES=1               Skip all prompts (for automation)
  RICE_VERBOSE=1           Show detailed output
  RICE_SKIP_SHELL_CHANGE=1 Don't change default shell to zsh
  GITHUB_TOKEN             Authenticate GitHub API requests

For more information: https://github.com/pentaxis93/rice
EOF
}

# Show version
show_version() {
  echo "rice v${RICE_VERSION}"
}

# Verify installation
verify_installation() {
  log_phase "Verification"

  local tools=(
    "zsh"
    "cargo"
    "go"
    "bun"
    "uv"
    "rg"
    "fd"
    "bat"
    "fzf"
    "zoxide"
    "hx"
    "lazygit"
    "delta"
    "lf"
    "jq"
    "tmux"
  )

  local failed=0
  local verified=0

  for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      ((verified++))
    else
      log_detail "Missing: $tool"
      ((failed++))
    fi
  done

  # Verify configs
  if verify_configs; then
    log_detail "Configs verified"
  else
    log_detail "Some configs missing"
    ((failed++))
  fi

  if [[ $failed -eq 0 ]]; then
    log_ok "All components verified" "$verified tools"
  else
    log_warn "$failed component(s) not found"
  fi

  state_complete_phase 9
  return $failed
}

# Print final summary
print_summary() {
  local end_time
  end_time=$(date +%s)
  local elapsed=$((end_time - RICE_START_TIME))

  local elapsed_str
  if [[ $elapsed -ge 60 ]]; then
    elapsed_str="$((elapsed / 60))m $((elapsed % 60))s"
  else
    elapsed_str="${elapsed}s"
  fi

  local installed
  installed="$(state_count_installed 2>/dev/null || echo "?")"
  local failed
  failed="$(state_count_failed 2>/dev/null || echo "0")"

  echo ""
  log_summary "$installed" "$elapsed_str" "$failed"

  if [[ "$RICE_FIRST_RUN" == "true" ]]; then
    echo ""
    echo "Next steps:"
    echo "  1. Run 'exec zsh' to start your new shell"
    echo "  2. Install a Nerd Font on your terminal client for best experience"
    echo ""
  fi
}

# Quick check for re-run (all components present)
is_complete_installation() {
  # Check a subset of key tools
  command -v zsh &>/dev/null && \
  command -v cargo &>/dev/null && \
  command -v rg &>/dev/null && \
  command -v hx &>/dev/null && \
  [[ -f "${RICE_STATE_DIR}/zshrc" ]]
}

# Compact output for re-runs
run_compact_check() {
  log_header "$RICE_VERSION" false
  echo ""
  echo "Checking installation..."
  echo ""

  RICE_CURRENT_PHASE=0

  # Phase counts (approximate)
  local phases=(
    "Prerequisites:7"
    "Runtimes:4"
    "Shell:5"
    "CLI Tools:9"
    "Developer Tools:7"
    "File Management:5"
    "System Utilities:10"
    "Infrastructure:1"
    "Configuration:synced"
  )

  for phase_info in "${phases[@]}"; do
    local name="${phase_info%%:*}"
    local count="${phase_info##*:}"
    RICE_CURRENT_PHASE=$((RICE_CURRENT_PHASE + 1))

    if [[ "$count" == "synced" ]]; then
      printf "[%d/%d] %-18s ${LOG_GREEN}${SYM_CHECK}${LOG_RESET} (%s)\n" \
        "$RICE_CURRENT_PHASE" "$RICE_TOTAL_PHASES" "$name" "$count"
    else
      printf "[%d/%d] %-18s ${LOG_GREEN}${SYM_CHECK}${LOG_RESET} (%2s/%-2s installed)\n" \
        "$RICE_CURRENT_PHASE" "$RICE_TOTAL_PHASES" "$name" "$count" "$count"
    fi
  done

  local installed
  installed="$(state_count_installed 2>/dev/null || echo "48")"

  echo ""
  echo "${LOG_GREEN}All ${installed} components verified.${LOG_RESET}"

  local end_time
  end_time=$(date +%s)
  local elapsed=$((end_time - RICE_START_TIME))
  echo "Completed in ${elapsed}.0s"
}

# Main installation flow
run_install() {
  # Detect environment
  detect_all || exit 1
  check_supported_os || exit 1

  # Initialize state
  state_init

  # Check for resume
  if state_is_resume; then
    local resume_phase
    resume_phase="$(state_get_resume_phase)"
    local phase_names=("Prerequisites" "Runtimes" "Shell" "CLI Tools" "Developer Tools" "File Management" "System Utilities" "Infrastructure" "Configuration" "Verification")
    local phase_name="${phase_names[$resume_phase]:-Unknown}"
    log_resume "$resume_phase" "$phase_name"
  fi

  # Print header
  log_header "$RICE_VERSION" "$RICE_FIRST_RUN"

  # Update timestamp
  state_update_timestamp

  # Ensure ~/.local/bin exists and is in PATH
  mkdir -p "${HOME}/.local/bin"
  export PATH="${HOME}/.local/bin:${PATH}"

  # Run phases
  install_prerequisites || ((RICE_FAILURES++))
  ensure_runtime_paths
  install_runtimes || ((RICE_FAILURES++))
  ensure_runtime_paths
  install_shell || ((RICE_FAILURES++))
  install_cli_tools || ((RICE_FAILURES++))
  install_dev_tools || ((RICE_FAILURES++))
  install_file_tools || ((RICE_FAILURES++))
  install_system_utils || ((RICE_FAILURES++))
  install_infrastructure || ((RICE_FAILURES++))
  deploy_configs || ((RICE_FAILURES++))

  # Verify
  verify_installation || ((RICE_FAILURES++))

  # Summary
  print_summary

  # Exit code
  if [[ $RICE_FAILURES -gt 0 ]]; then
    exit 2  # Partial success
  fi
  exit 0
}

# Run doctor command
run_doctor() {
  exec "${RICE_INSTALL_DIR}/bin/rice-doctor"
}

# Run status command
run_status() {
  exec "${RICE_INSTALL_DIR}/bin/rice-status"
}

# Run update command
run_update() {
  echo "Fetching latest rice..."

  # Download and run latest
  curl -fsSL "https://raw.githubusercontent.com/pentaxis93/rice/main/install.sh" | bash
}

# Main entry point
main() {
  local command="${1:-}"

  case "$command" in
    help|--help|-h)
      show_help
      exit 0
      ;;
    version|--version|-v)
      show_version
      exit 0
      ;;
    doctor)
      run_doctor
      ;;
    status)
      run_status
      ;;
    update)
      run_update
      ;;
    "")
      # Check if this might be a quick re-run
      if is_complete_installation && [[ "${RICE_FIRST_RUN:-}" != "true" ]]; then
        state_init  # Need to init to check first run
        if [[ "$RICE_FIRST_RUN" != "true" ]]; then
          # Always sync configs even on re-run
          deploy_configs
          run_compact_check
          exit 0
        fi
      fi

      run_install
      ;;
    *)
      echo "Unknown command: $command"
      echo "Run 'rice help' for usage"
      exit 1
      ;;
  esac
}

main "$@"
