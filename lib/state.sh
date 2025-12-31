#!/usr/bin/env bash
# rice state tracking for idempotency and resume capability

# State file location (exported for use in other modules)
RICE_STATE_DIR="${HOME}/.config/rice"
RICE_STATE_FILE="${RICE_STATE_DIR}/state.json"
RICE_BACKUPS_DIR="${RICE_STATE_DIR}/backups"
RICE_VERSION_CACHE="${RICE_STATE_DIR}/version_cache.json"    # used in lib/versions.sh
RICE_VERSION_OVERRIDES="${RICE_STATE_DIR}/version_overrides" # used in lib/versions.sh
export RICE_STATE_DIR RICE_STATE_FILE RICE_BACKUPS_DIR RICE_VERSION_CACHE RICE_VERSION_OVERRIDES

# Initialize state directory and file
state_init() {
  mkdir -p "$RICE_STATE_DIR" "$RICE_BACKUPS_DIR"

  if [[ ! -f "$RICE_STATE_FILE" ]]; then
    # First run - create initial state
    RICE_FIRST_RUN=true
    state_create
  else
    RICE_FIRST_RUN=false
  fi

  export RICE_FIRST_RUN
}

# Create initial state file
state_create() {
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  cat > "$RICE_STATE_FILE" << EOF
{
  "_rice": "https://github.com/pentaxis93/rice",
  "version": "${RICE_VERSION:-1.0.0}",
  "created": "${now}",
  "last_run": "${now}",
  "completed_phases": [],
  "current_phase": 0,
  "current_tool": null,
  "tools": {}
}
EOF
}

# Read a value from state using jq
state_get() {
  local key="$1"
  if [[ -f "$RICE_STATE_FILE" ]] && command -v jq &>/dev/null; then
    jq -r "$key // empty" "$RICE_STATE_FILE" 2>/dev/null
  fi
}

# Update state file (requires jq)
state_set() {
  local key="$1"
  local value="$2"

  if ! command -v jq &>/dev/null; then
    # jq not available yet, skip state updates
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  jq "$key = $value" "$RICE_STATE_FILE" > "$tmp" && mv "$tmp" "$RICE_STATE_FILE"
}

# Update last_run timestamp
state_update_timestamp() {
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  state_set ".last_run" "\"$now\""
}

# Mark current phase
state_set_phase() {
  local phase="$1"
  state_set ".current_phase" "$phase"
}

# Mark phase as completed
state_complete_phase() {
  local phase="$1"

  if ! command -v jq &>/dev/null; then
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  jq ".completed_phases |= (. + [$phase] | unique | sort)" "$RICE_STATE_FILE" > "$tmp" \
    && mv "$tmp" "$RICE_STATE_FILE"
}

# Check if phase is completed
state_phase_completed() {
  local phase="$1"

  if ! command -v jq &>/dev/null; then
    return 1
  fi

  local completed
  completed="$(jq ".completed_phases | contains([$phase])" "$RICE_STATE_FILE" 2>/dev/null)"
  [[ "$completed" == "true" ]]
}

# Set current tool being installed (for resume)
state_set_current_tool() {
  local tool="$1"
  state_set ".current_tool" "\"$tool\""
}

# Clear current tool
state_clear_current_tool() {
  state_set ".current_tool" "null"
}

# Get current tool (for resume message)
state_get_current_tool() {
  state_get ".current_tool"
}

# Record tool installation
# Usage: state_record_tool "toolname" "version" "method" ["extra_key" "extra_value"]...
state_record_tool() {
  local tool="$1"
  local version="$2"
  local method="$3"
  shift 3

  if ! command -v jq &>/dev/null; then
    return 0
  fi

  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  # Build the tool object
  local tool_json
  tool_json="{\"installed\": true, \"version\": \"$version\", \"method\": \"$method\", \"installed_at\": \"$now\""

  # Add extra key-value pairs
  while [[ $# -ge 2 ]]; do
    tool_json+=", \"$1\": \"$2\""
    shift 2
  done

  tool_json+="}"

  local tmp
  tmp="$(mktemp)"
  jq ".tools[\"$tool\"] = $tool_json" "$RICE_STATE_FILE" > "$tmp" && mv "$tmp" "$RICE_STATE_FILE"
}

# Check if tool is installed (according to state)
state_tool_installed() {
  local tool="$1"
  local installed
  installed="$(state_get ".tools[\"$tool\"].installed")"
  [[ "$installed" == "true" ]]
}

# Get tool version from state
state_tool_version() {
  local tool="$1"
  state_get ".tools[\"$tool\"].version"
}

# Get tool method from state
state_tool_method() {
  local tool="$1"
  state_get ".tools[\"$tool\"].method"
}

# Mark tool as failed
state_record_tool_failed() {
  local tool="$1"
  local error="$2"

  if ! command -v jq &>/dev/null; then
    return 0
  fi

  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  local tmp
  tmp="$(mktemp)"
  jq ".tools[\"$tool\"] = {\"installed\": false, \"error\": \"$error\", \"failed_at\": \"$now\"}" \
    "$RICE_STATE_FILE" > "$tmp" && mv "$tmp" "$RICE_STATE_FILE"
}

# Get resume phase (first incomplete phase)
state_get_resume_phase() {
  if ! command -v jq &>/dev/null; then
    echo "0"
    return
  fi

  local current
  current="$(state_get ".current_phase")"
  echo "${current:-0}"
}

# Check if this is a resume (incomplete previous run)
state_is_resume() {
  if [[ ! -f "$RICE_STATE_FILE" ]]; then
    return 1
  fi

  local current_tool
  current_tool="$(state_get_current_tool)"

  # If there was a current_tool set, it means we were interrupted
  [[ -n "$current_tool" && "$current_tool" != "null" ]]
}

# Get count of installed tools
state_count_installed() {
  if ! command -v jq &>/dev/null; then
    echo "0"
    return
  fi

  jq '[.tools | to_entries[] | select(.value.installed == true)] | length' "$RICE_STATE_FILE" 2>/dev/null || echo "0"
}

# Get count of failed tools
state_count_failed() {
  if ! command -v jq &>/dev/null; then
    echo "0"
    return
  fi

  jq '[.tools | to_entries[] | select(.value.installed == false)] | length' "$RICE_STATE_FILE" 2>/dev/null || echo "0"
}

# Print state summary (for rice status command)
state_print_summary() {
  if [[ ! -f "$RICE_STATE_FILE" ]]; then
    echo "No rice state file found."
    echo "Run 'rice' to install."
    return 1
  fi

  echo "State file: $RICE_STATE_FILE"
  echo ""

  local last_run version
  last_run="$(state_get ".last_run")"
  version="$(state_get ".version")"

  echo "rice version: $version"
  echo "Last run: $last_run"
  echo ""

  local installed failed
  installed="$(state_count_installed)"
  failed="$(state_count_failed)"

  echo "Tools: $installed installed, $failed failed"
}
