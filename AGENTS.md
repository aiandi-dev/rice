# AGENTS.md

Instructions for AI coding assistants working on the rice project.

<!-- OPENSPEC:START -->
Always open `@/openspec/AGENTS.md` when the request mentions planning, proposals, specs,
new capabilities, breaking changes, or architecture shifts.
<!-- OPENSPEC:END -->

## Project Overview

**rice** is an opinionated terminal environment installer for servers and workstations. One command sets up a complete modern shell environment with zsh, modern CLI tools, and sensible configs.

- Target: VPS/server environments, desktop workstations
- Currently supports: Debian

## Build/Lint/Test Commands

```bash
# Lint all shell scripts
shellcheck install.sh lib/*.sh bin/*

# Lint a single file
shellcheck lib/tools.sh

# Docker smoke test (build + run)
docker build -t rice-test -f test/docker/Dockerfile.debian .
docker run --rm rice-test

# Interactive debugging
docker run --rm -it rice-test bash

# Manual testing
./install.sh                    # Run installer (idempotent)
./bin/rice-doctor               # Check installation health
./bin/rice-status               # Show installed components
RICE_VERBOSE=1 ./install.sh     # Verbose output

# Idempotency test
./install.sh && ./install.sh    # Second run should be fast
```

## Code Style Guidelines

### Bash Conventions

- Shebang: `#!/usr/bin/env bash`
- Strict mode: `set -euo pipefail` at top of executable scripts
- Conditionals: Use `[[ ]]` not `[ ]`
- Variables: Always quote - `"$var"` not `$var`
- Case: lowercase for local vars, UPPERCASE for exported/environment
- Functions: snake_case - `install_package`, `detect_os`
- Command existence: Use `command -v cmd &>/dev/null` not `which`

### File Structure

- `install.sh` - Entry point (curl | bash target)
- `lib/` - Sourced library modules (log.sh, detect.sh, state.sh, packages.sh, tools.sh, runtimes.sh, config.sh)
- `configs/` - Deployed configuration files
- `bin/` - Utility commands (rice-doctor, rice-status)
- `test/docker/` - Dockerfiles for testing

### Logging (lib/log.sh)

```bash
log_phase "Phase Name"      # Blue, phase header [N/9]
log_step "message"          # Blue bullet, step announcement
log_ok "component" "ver"    # Green checkmark, success
log_warn "message"          # Yellow warning
log_error "message"         # Red cross, error
log_detail "message"        # Gray, verbose only (RICE_VERBOSE=1)
log_installing "component"  # Installing indicator
```

Never use bare `echo` for user-facing output.

### Idempotency Pattern

Every installation function MUST check before installing:

```bash
install_ripgrep() {
  if command -v rg &>/dev/null; then
    local version
    version=$(rg --version 2>/dev/null | head -1 | awk '{print $2}')
    log_ok "ripgrep" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "ripgrep"
  apt_install "ripgrep" "ripgrep"
  local result=$?
  state_clear_current_tool
  return $result
}
```

### State Tracking (lib/state.sh)

State is tracked in `~/.config/rice/state.json`:
- `state_record_tool "name" "version" "method"` - after successful install
- `state_record_tool_failed "name" "error"` - on failure
- `state_set_current_tool` / `state_clear_current_tool` - for resume support
- `state_complete_phase N` - when a phase finishes

### Error Handling

- Functions return non-zero on failure
- Use `((failed++))` pattern to count failures within phases
- Log errors with `log_error` before returning

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Functions | snake_case | `install_ripgrep`, `ensure_alias` |
| Local vars | lowercase | `local version`, `local failed=0` |
| Exported vars | UPPERCASE | `RICE_VERSION`, `RICE_VERBOSE` |
| Files | lowercase, hyphens ok | `rice-doctor`, `config.toml` |

## Environment Variables

- `RICE_YES=1` - Skip all prompts (for automation)
- `RICE_VERBOSE=1` - Show detailed output
- `RICE_SKIP_SHELL_CHANGE=1` - Don't change default shell to zsh
- `GITHUB_TOKEN` - Authenticate GitHub API requests (avoids rate limits)

## Commit Style

```
type: short description

Longer explanation if needed.
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## Do Not

- Add GUI tools or desktop components
- Make it configurable with flags for tool selection
- Add tools that aren't universally useful on servers
- Break idempotency
- Require user interaction without `RICE_YES` escape hatch
- Install anything without checking if it exists first
- Use `echo` for user-facing output (use log functions)
- Skip shellcheck validation

## Adding a New Tool

1. Create install function in `lib/tools.sh` following idempotency pattern
2. Add to phase function (e.g., `install_cli_tools`)
3. Add verification check in `verify_installation()` in `install.sh`
4. Add to `rice-doctor` checks in `bin/rice-doctor`
5. Run `shellcheck` on modified files
6. Test in Docker container
