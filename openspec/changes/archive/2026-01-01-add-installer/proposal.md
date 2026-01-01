# Change: Add rice installer capability

## Why

rice is a new project. This proposal defines the complete installer specification for an opinionated terminal environment for headless servers. One command sets up a complete modern shell environment.

Target: VPS and server environments where you SSH in and want to get to work.

## What Changes

- **ADDED** Complete installer specification including:
  - **Self-maintaining architecture** (no periodic version pin updates required)
  - 10-phase installation process (Prerequisites → Verification)
  - Idempotent, resumable installation with state tracking
  - Binary download protocol with upstream checksum verification
  - Self-maintaining version strategy (fetch latest, verify against upstream checksums)
  - Shell setup (zsh, oh-my-zsh, powerlevel10k, plugins)
  - Modern CLI tools (fd, rg, bat, fzf, zoxide, atuin, etc.)
  - Developer tools (tmux, helix, lazygit, delta, gh)
  - Configuration deployment with marker-based management
  - Diagnostic commands (rice doctor, rice status)
  - Non-interactive mode for automation

## Impact

- Affected specs: `installer` (new capability)
- Affected code: All of `install.sh`, `lib/`, `configs/`, `bin/`

## Design Decisions

Key architectural choices documented in the spec:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Shell | zsh + oh-my-zsh + p10k | Instant prompt for SSH, familiar plugin ecosystem |
| Editor | helix | Modal, tree-sitter built-in, zero config needed |
| File manager | lf | Mature, stable, lightweight (3MB) |
| Version strategy | Fetch latest + upstream checksums | Self-maintaining, zero maintainer attention required |
| Package install | OS-native first | apt before cargo/go when possible |

## Governance

This proposal incorporates the version strategy amendment from governance transmission `gov-2025-12-31-rice-self-maintaining-versions`, which established:
- Fetch latest stable release at runtime (not pinned versions)
- Verify against upstream-published checksums (not maintainer-maintained)
- Optional user overrides via `~/.config/rice/version_overrides`
