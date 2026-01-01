# Project Context

## Purpose

**rice** is an opinionated terminal environment installer for servers and workstations.

One command sets up a complete modern shell environment: zsh with sane defaults, a fast prompt, and CLI tools that replace rusty coreutils. Designed for VPS environments where you SSH in, or for unifying your workflow across local machines.

**Goals:**
- Zero-config productivity out of the box
- Idempotent installation (run twice, nothing breaks)
- Minimal surface area (only what's needed for terminal productivity)
- Transparent operation (users can read and understand the script)

**Non-goals:**
- GUI tools, desktop environments, window managers
- Excessive configurability or framework-like flexibility
- Tools that aren't universally useful on servers

## Tech Stack

- **Language:** Bash (POSIX-compatible where possible)
- **Target OS:** Debian (planned: additional Linux distros)
- **Package Sources:** OS-native first (apt), then upstream installers (curl | bash)
- **Config Location:** `~/.config/rice/` (XDG-compliant)

For the complete list of installed tools and requirements, see `specs/installer/spec.md`.

## Project Conventions

### Code Style

- Shebang: `#!/usr/bin/env bash`
- Strict mode: `set -euo pipefail`
- Conditionals: `[[ ]]` not `[ ]`
- Variables: Always quoted (`"$var"` not `$var`)
- Naming: `snake_case` for functions, `lowercase` for locals, `UPPERCASE` for exported/env
- Command checks: `command -v` over `which`
- Idempotency: Always check before installing

**Example pattern:**
```bash
install_ripgrep() {
  if command -v rg &>/dev/null; then
    log_ok "ripgrep already installed"
    return 0
  fi

  log_step "Installing ripgrep..."
  case "$RICE_OS" in
    debian|ubuntu) sudo apt-get install -y ripgrep ;;
    *)             log_error "Unsupported OS: $RICE_OS"; return 1 ;;
  esac

  log_ok "ripgrep installed"
}
```

### Logging

Use consistent logging functions (no bare `echo` for user output):
- `log_step "message"` — Blue, phase announcements
- `log_ok "message"` — Green, success
- `log_warn "message"` — Yellow, warnings
- `log_error "message"` — Red, errors
- `log_detail "message"` — Gray, verbose details

### Architecture

```
rice/
├── install.sh          # Single entry point (curl | bash target)
├── VERSION             # Semantic version
├── configs/            # Dotfiles deployed to ~/.config/rice/
│   ├── zshrc
│   ├── tmux.conf
│   ├── p10k.zsh
│   ├── aliases.sh
│   ├── helix/
│   │   └── config.toml
│   └── lf/
│       └── lfrc
├── lib/                # Modular functionality
│   ├── log.sh          # Logging utilities
│   ├── detect.sh       # OS/arch detection
│   ├── packages.sh     # Package manager abstraction
│   ├── shell.sh        # zsh/oh-my-zsh setup
│   ├── tools.sh        # CLI tool installation
│   └── runtimes.sh     # Language runtime installation
└── test/docker/        # Dockerfiles for testing
```

**Key decisions:**
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Shell | zsh | Widest plugin ecosystem |
| Prompt | powerlevel10k | Fast, pretty, zero-config |
| Editor | helix | Modern modal editor; sane defaults, no plugins needed |
| File manager | lf | Fast, minimal, vi-like keybindings |
| Package install | OS-native first | apt before cargo/npm |
| Config location | ~/.config/rice/ | XDG-compliant |

### Testing Strategy

1. **Shellcheck** — All scripts must pass `shellcheck`
2. **Docker smoke test** — Run installer in fresh container
   ```bash
   docker build -t rice-test -f test/docker/Dockerfile.debian .
   docker run --rm rice-test
   ```
3. **Idempotency test** — Run installer twice; second run should be fast with no errors

### Git Workflow

**Commit format:**
```
type: short description

Longer explanation if needed.
```

**Types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## Domain Context

**Environment variables respected:**
- `RICE_YES=1` — Skip all prompts (automation mode)
- `RICE_VERBOSE=1` — Show detailed output
- `RICE_SKIP_SHELL_CHANGE=1` — Don't change default shell to zsh
- `GITHUB_TOKEN` — Authenticate GitHub API requests (avoids rate limits)

**Target user:** Developer who wants a productive, zero-config terminal environment immediately, whether on a remote VPS or local machine.

## Important Constraints

1. **No GUI** — Headless servers only
2. **Idempotent** — Every operation must be safe to repeat
3. **No interaction** — Must work with `RICE_YES=1` escape hatch
4. **Check before install** — Never blindly reinstall
5. **OS-native packages preferred** — apt/dnf/pacman before cargo/npm
6. **No security vulnerabilities** — Validate inputs, no command injection
