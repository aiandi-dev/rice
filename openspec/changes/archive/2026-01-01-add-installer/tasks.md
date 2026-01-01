# Implementation Tasks

## 1. Project Structure
- [x] 1.1 Create directory structure (`lib/`, `configs/`, `bin/`, `test/`)
- [x] 1.2 Create `VERSION` file (1.0.0)
- [x] 1.3 Create main `install.sh` entry point with argument parsing

## 2. Library: Core Utilities
- [x] 2.1 Create `lib/log.sh` (log_step, log_ok, log_warn, log_error, log_detail)
- [x] 2.2 Create `lib/detect.sh` (OS detection, architecture detection)
- [x] 2.3 Create `lib/state.sh` (state.json read/write, phase tracking)
- [x] 2.4 Create `lib/versions.sh` — **critical: implements self-maintaining strategy**
  - [x] 2.4.1 `get_latest_release` (GitHub API query)
  - [x] 2.4.2 `get_upstream_checksum` (fetch from release assets)
  - [x] 2.4.3 Version caching (1-hour TTL, graceful degradation)
  - [x] 2.4.4 `check_version_override` (user pin support)

## 3. Library: Installation
- [x] 3.1 Create `lib/packages.sh` (apt wrapper with quiet mode)
- [x] 3.2 Create `lib/download.sh` (binary download, checksum verification, retry logic)
- [x] 3.3 Create `lib/runtimes.sh` (cargo, go, bun, uv installation)
- [x] 3.4 Create `lib/shell.sh` (zsh, oh-my-zsh, p10k, plugins)
- [x] 3.5 Create `lib/tools.sh` (CLI tools installation)

## 4. Configurations
- [x] 4.1 Create `configs/zshrc` (PATH setup, plugin config, integrations)
- [x] 4.2 Create `configs/p10k.zsh` (lean preset, ASCII-compatible)
- [x] 4.3 Create `configs/tmux.conf` (sensible defaults)
- [x] 4.4 Create `configs/aliases.sh` (ls→lsd, cat→bat, etc.)
- [x] 4.5 Create `configs/helix/config.toml` (editor config)
- [x] 4.6 Create `configs/lf/lfrc` (file manager config)
- [x] 4.7 Create `configs/gitconfig` (delta integration)
- [x] 4.8 Create `configs/welcome.txt` (first-run message)

## 5. Phase Implementation
- [x] 5.1 Phase 0: Prerequisites (git, curl, build-essential, etc.)
- [x] 5.2 Phase 1: Runtimes (cargo, go, bun, uv)
- [x] 5.3 Phase 2: Shell (zsh, oh-my-zsh, p10k, plugins, direnv)
- [x] 5.4 Phase 3: CLI Tools (fd, rg, bat, fzf, zoxide, atuin, jq, ast-grep)
- [x] 5.5 Phase 4: Dev Tools (tmux, helix, lazygit, delta, gh, git-lfs, opencode)
- [x] 5.6 Phase 5: File Management (lf, tree, trash-cli, atool, p7zip)
- [x] 5.7 Phase 6: System Utilities (rsync, lsof, htop, btop, ncdu, etc.)
- [x] 5.8 Phase 7: Infrastructure (tailscale)
- [x] 5.9 Phase 8: Configuration deployment
- [x] 5.10 Phase 9: Verification

## 6. Diagnostic Commands
- [x] 6.1 Create `bin/rice-doctor` (health checks)
- [x] 6.2 Create `bin/rice-status` (show installed components)
- [x] 6.3 Add help/version/update subcommands to install.sh

## 7. Error Handling
- [x] 7.1 Implement interrupt handler (SIGINT/SIGTERM trap)
- [x] 7.2 Implement resume capability (detect incomplete state)
- [x] 7.3 Implement self-contained error messages with recovery steps
- [x] 7.4 Implement exit code integrity (verify before exit 0)

## 8. Output Formatting
- [x] 8.1 Implement fresh install output format (detailed per-tool)
- [x] 8.2 Implement re-run output format (compact summary)
- [x] 8.3 Implement installation summary box
- [x] 8.4 Implement first-run detection and tagline

## 9. Testing
- [x] 9.1 Create `test/docker/Dockerfile.debian` for smoke testing
- [x] 9.2 Verify shellcheck passes on all scripts
- [ ] 9.3 Test idempotency (run twice, second is fast/no-op)
- [ ] 9.4 Test interrupt/resume flow
- [ ] 9.5 Test non-interactive mode (RICE_YES=1)

## 10. Documentation
- [x] 10.1 Create README.md with installation instructions
- [x] 10.2 Document environment variables
- [x] 10.3 Document uninstall procedure
