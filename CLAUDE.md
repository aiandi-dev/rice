<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# CLAUDE.md

## Project Overview

**rice** is an opinionated terminal environment installer for servers and workstations. One command sets up a complete modern shell environment.

Target: VPS/server environments, or desktop workstations where a focused CLI workflow is desired.

Currently supports: Debian

## Philosophy

1. **Opinionated, not configurable** — We make choices so users don't have to. No flags to customize tool selection.
2. **Idempotent** — Run it N times, get the same result. This is the update mechanism: re-run rice.
3. **Minimal surface area** — Only what's needed for terminal productivity. No GUI, no desktop, no bloat.
4. **Transparent** — Users can read the script and understand what it does.
5. **Resilient** — Partial failures don't leave broken state. Resume from where you left off.

## Architecture

```
rice/
├── install.sh              # Single entry point (curl | bash target)
├── CLAUDE.md               # This file
├── README.md               # User documentation
├── SPEC.md                 # Detailed specification
├── VERSION                 # Semantic version
├── configs/
│   ├── zshrc               # Shell configuration
│   ├── tmux.conf           # Tmux configuration
│   ├── p10k.zsh            # Powerlevel10k config
│   ├── aliases.sh          # Shell aliases
│   ├── helix/
│   │   └── config.toml     # Helix editor config
│   └── lf/
│       └── lfrc            # lf file manager config
├── lib/
│   ├── log.sh              # Logging utilities
│   ├── detect.sh           # OS/arch detection
│   ├── state.sh            # State tracking for idempotency
│   ├── download.sh         # Binary download with verification
│   ├── packages.sh         # Package manager abstraction
│   ├── shell.sh            # zsh/oh-my-zsh setup
│   ├── tools.sh            # CLI tool installation
│   └── runtimes.sh         # Language runtime installation
├── bin/
│   ├── rice-doctor         # Diagnostic command
│   └── rice-status         # Status command
└── test/
    └── docker/             # Dockerfiles for testing on each OS
```

## Installation Phases

| Phase | Name | Contents |
|-------|------|----------|
| 0 | Prerequisites | git, curl, build-essential, etc. |
| 1 | Runtimes | cargo, go, bun, uv |
| 2 | Shell | zsh, oh-my-zsh, p10k, plugins, direnv |
| 3 | CLI Tools | fd, rg, bat, fzf, zoxide, atuin, jq, ast-grep, opencode |
| 4 | Dev Tools | tmux, helix, lazygit, gh, git-lfs |
| 5 | File Management | lf, tree, trash-cli, atool, p7zip |
| 6 | System Utilities | rsync, lsof, htop, btop, ncdu, etc. |
| 7 | Infrastructure | tailscale |
| 8 | Configuration | Deploy all configs |
| 9 | Verification | Verify all tools work |

## Code Style

### Bash

- Use `#!/usr/bin/env bash` shebang
- Set strict mode: `set -euo pipefail`
- Use `[[ ]]` for conditionals, not `[ ]`
- Quote variables: `"$var"` not `$var`
- Use lowercase for local variables, UPPERCASE for exported/environment
- Functions use snake_case: `install_package`, `detect_os`
- Prefer `command -v` over `which` for checking if commands exist
- Always check before installing: makes scripts idempotent

### Example Pattern

```bash
install_ripgrep() {
  if command -v rg &>/dev/null; then
    log_ok "ripgrep already installed"
    return 0
  fi

  log_step "Installing ripgrep..."
  apt_install "ripgrep" "ripgrep"
  log_ok "ripgrep installed"
}
```

### Logging

Use consistent logging functions:
- `log_step "message"` — Blue, for phase/step announcements
- `log_ok "message"` — Green checkmark, for success
- `log_warn "message"` — Yellow, for warnings
- `log_error "message"` — Red, for errors
- `log_detail "message"` — Gray, for verbose details

No bare `echo` statements for user-facing output.

## State Tracking

State is tracked in `~/.config/rice/state.json`:

```json
{
  "version": "1.0.0",
  "last_run": "2025-12-31T10:30:00Z",
  "completed_phases": [0, 1, 2, 3],
  "current_phase": 4,
  "tools": {
    "rg": {"installed": true, "version": "14.1.0", "method": "apt"},
    "fd": {"installed": true, "version": "9.0.0", "method": "apt", "symlinked": true}
  }
}
```

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Shell | zsh | Widest plugin ecosystem, good defaults |
| Prompt | powerlevel10k | Fast, pretty, zero-config with our p10k.zsh |
| Editor | helix | Modern, no config needed, tree-sitter built-in |
| Package install | OS-native first | apt before cargo/go when possible |
| Config location | ~/.config/rice/ | XDG-compliant, single cleanup point |
| Runtime installer | curl \| bash | Standard for bun, rustup, uv |

## Environment Variables

The installer respects:
- `RICE_YES=1` — Skip all prompts (for automation)
- `RICE_VERBOSE=1` — Show detailed output
- `RICE_SKIP_SHELL_CHANGE=1` — Don't change default shell to zsh
- `GITHUB_TOKEN` — Authenticate GitHub API requests (avoids rate limits)

## Commands

| Command | Purpose |
|---------|---------|
| `rice` | Run installer (idempotent) |
| `rice doctor` | Diagnose installation health |
| `rice status` | Show what's installed and managed |
| `rice update` | Fetch latest rice and re-run |

## Testing

Before committing changes:

1. **Shellcheck** — All scripts must pass `shellcheck`
2. **Docker smoke test** — Run installer in fresh container
   ```bash
   docker build -t rice-test -f test/docker/Dockerfile.debian .
   docker run --rm rice-test
   ```
3. **Idempotency test** — Run installer twice, second run should be fast with no errors

## Do Not

- Add GUI tools or desktop components
- Make it configurable with flags for tool selection
- Add tools that aren't universally useful on servers
- Break idempotency
- Require user interaction without `RICE_YES` escape hatch
- Install anything without checking if it exists first
- Use `echo` for user-facing output (use log functions)

## Commit Style

```
type: short description

Longer explanation if needed.
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
