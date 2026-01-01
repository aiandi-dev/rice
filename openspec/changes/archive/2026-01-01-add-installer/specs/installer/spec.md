# Installer Specification

The rice installer provides a complete terminal environment for headless servers via a single command.

## Design Principles

### Idempotency
rice is an idempotent installer. Running it N times produces the same result as running it once. This enables:
- Re-running after partial failures
- Updating to new versions by re-running
- Using rice as the canonical source of system configuration

### Opinionated Choices
rice makes decisions so users don't have to. There are no flags to customize tool selection—you get the rice stack or you don't use rice.

### Output Philosophy

rice output is calm, informative, and scannable.

**Principles:**
- Phase counter sets expectations (`[3/9]`)
- Version numbers build confidence (`✓ cargo (1.75.0)`)
- Skipped components confirm idempotency (`skipped`)
- Errors are self-contained with recovery steps
- Color has semantic meaning, not decoration

**Anti-patterns rice avoids:**
- apt's verbose package installation output
- Blank lines between every log statement
- Color for decoration (only for semantics)
- "downloading..." without progress indication
- Spinners for operations < 1 second
- Requiring user to scroll up to find errors
- Exiting 0 when any component is broken

**Graceful unavailability:**
When a component is unavailable but a fallback exists, use success framing:
- `✓ btop (unavailable, htop installed)` — not `⚠ btop: package not found`
- Checkmark indicates the user's need was met
- Parenthetical explains without alarming
- Name what IS there, not just what isn't

This pattern applies wherever fallbacks exist. Handled constraints are successes.

---

## Key Decisions

### Shell: p10k + oh-my-zsh (not starship + zimfw)

p10k's instant prompt provides immediate shell responsiveness over SSH—the shell is usable while plugins load in the background. oh-my-zsh provides the familiar plugin ecosystem (autosuggestions, syntax-highlighting).

starship is simpler (single binary, TOML config) but lacks instant prompt. For SSH-heavy workflows, instant prompt wins.

### File manager: lf (not yazi)

lf is mature (6+ years), stable, and lightweight (3MB). yazi is faster with async operations and image preview, but image preview is irrelevant on headless servers.

Revisit for v2 if yazi proves stable and adds compelling non-visual features.

### Editor: helix (not micro, not neovim)

helix is modal (efficient once learned), has tree-sitter built-in (syntax highlighting without config), and requires no plugin management. It's opinionated—which matches rice philosophy.

micro is simpler but less powerful. neovim requires extensive configuration. helix is the sweet spot.

---

## Dependency Graph

Installation proceeds in phases. Each phase completes before the next begins.

### Phase 0: Prerequisites
git, curl, sudo, build-essential, unzip, pkg-config, libssl-dev

### Phase 1: Runtimes (required)
- cargo (via rustup)
- go
- bun
- uv

### Phase 2: Shell
- zsh
- oh-my-zsh → requires: zsh
- powerlevel10k → requires: oh-my-zsh
- zsh-autosuggestions → requires: oh-my-zsh
- zsh-syntax-highlighting → requires: oh-my-zsh
- direnv

### Phase 3: CLI Tools
Tools installed via apt where available, cargo/go fallback where needed.
- fd → apt preferred, cargo fallback
- ast-grep → requires: cargo
- lsd → apt preferred, cargo fallback
- bat → apt preferred, cargo fallback
- ripgrep → apt
- fzf → apt
- zoxide → upstream installer
- atuin → upstream installer
- jq → apt
- opencode → requires: go

### Phase 4: Developer Tools
- tmux → apt
- helix → binary download
- lazygit → binary download
- delta → binary download
- gh → apt
- git-lfs → apt

### Phase 5: File Management
- lf → binary download
- tree → apt
- trash-cli → apt
- atool → apt
- p7zip → apt

### Phase 6: System Utilities
- rsync → apt
- lsof → apt
- dnsutils → apt
- netcat → apt
- strace → apt
- htop → apt
- btop → apt (if available)
- ncdu → apt
- watch → apt

### Phase 7: Infrastructure
- tailscale → upstream installer

### Phase 8: Configuration
Config deployment after all tools installed.

### Phase 9: Verification
Post-install verification of all components.

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0    | Complete success |
| 1    | Fatal error (couldn't continue) |
| 2    | Partial success (some tools failed, see summary) |
| 130  | User interrupted (Ctrl+C) |

---

## Output Formats

### Progress Output (Fresh Install)

```
rice v1.0.0
Your terminal, seasoned.

[1/9] Prerequisites
  ✓ git
  ✓ curl
  • build-essential
  ✓ build-essential

[2/9] Runtimes
  ✓ cargo (1.75.0, skipped)
  • bun
  ✓ bun (1.0.25)
  ✓ go (1.22.0, skipped)
  • uv
  ✓ uv (0.1.0)

[3/9] Shell
  ...
```

**Format rules:**
- `•` (bullet) prefix for "installing now"
- `✓` (green) prefix for "success" or "skipped"
- `✗` (red) prefix for "failed"
- Version in parentheses when available
- `skipped` suffix for already-installed components
- Phase counter `[N/9]` at start of each phase

### Progress Output (Re-run, Nothing to Do)

```
rice v1.0.0

Checking installation...

[1/9] Prerequisites     ✓ (7/7 installed)
[2/9] Runtimes          ✓ (4/4 installed)
[3/9] Shell             ✓ (5/5 installed)
[4/9] CLI Tools         ✓ (10/10 installed)
[5/9] Developer Tools   ✓ (7/7 installed)
[6/9] File Management   ✓ (5/5 installed)
[7/9] System Utilities  ✓ (10/10 installed)
[8/9] Infrastructure    ✓ (1/1 installed)
[9/9] Configuration     ✓ (synced)

All 32 components verified.
Completed in 2.3s
```

**Rules:**
- Compact format when all components present
- Count format `(N/N installed)` for phases
- Total elapsed time at end
- No tagline on re-run (only first install)

**Alignment rules:**
- Phase names right-padded to 18 characters
- Counts right-aligned within column
- Checkmarks align vertically
- Single-digit counts get leading space for alignment

Example with alignment:
```
[1/9] Prerequisites     ✓ ( 7/7  installed)
[2/9] Runtimes          ✓ ( 4/4  installed)
[3/9] Shell             ✓ ( 5/5  installed)
[4/9] CLI Tools         ✓ (10/10 installed)
[5/9] Developer Tools   ✓ ( 6/6  installed)
[6/9] File Management   ✓ ( 5/5  installed)
[7/9] System Utilities  ✓ (10/10 installed)
[8/9] Infrastructure    ✓ ( 1/1  installed)
[9/9] Configuration     ✓ (synced)
```

Alignment is invisible when present, distracting when absent. The terminal
is a grid—respecting it communicates precision.

### First-Run Detection

- **First run:** `~/.config/rice/state.json` does not exist
- **Re-run:** state file exists
- Tagline "Your terminal, seasoned." shown only on first run

---

## ADDED Requirements

### Requirement: Self-contained error messages
The system SHALL display errors that include problem, context, and recovery steps.

#### Scenario: Error message format
- **WHEN** an error occurs during installation
- **THEN** display error in format:
  ```
  ✗ Failed: {component} {operation}

    Error: {specific error message}
    {additional context if relevant}

    Try:
      1. {first recovery step}
      2. {second recovery step}

    If this persists, report: https://github.com/you/rice/issues
  ```

#### Scenario: Checksum failure
- **WHEN** checksum verification fails for a binary download
- **THEN** display expected vs actual checksums
- **AND** suggest removing cached file and re-running

#### Scenario: Network failure
- **WHEN** a network request times out
- **THEN** display the URL that failed
- **AND** suggest checking internet connection

### Requirement: State tracking
The system SHALL track installation state for idempotency and resume capability.

#### Scenario: State file format
- **WHEN** writing state file
- **THEN** pretty-print with 2-space indent
- **AND** include `_rice` key first with project URL
- **AND** use ISO 8601 timestamps
- **AND** record tool method and any special handling

### Requirement: Interrupt handling
The system SHALL handle interrupts gracefully and preserve state for resume.

#### Scenario: Interrupt message
- **WHEN** interrupted
- **THEN** show current phase and tool
- **AND** show path to state file
- **AND** show command to resume
- **AND** show command to start fresh

### Requirement: Resume capability
The system SHALL detect incomplete state and resume from the last incomplete step.

#### Scenario: Resume notification
- **WHEN** resuming from interrupted state
- **THEN** display "Resuming from [N/9] Phase Name..."
- **AND** display "State preserved from previous run."

### Requirement: Clear failure messages
The system SHALL log specific errors and continue to remaining steps without aborting.

#### Scenario: Non-fatal failure
- **WHEN** a tool installation fails
- **THEN** mark it as failed in state
- **AND** continue with remaining tools
- **AND** include in final summary

### Requirement: Exit code integrity
The system SHALL verify all components before returning exit code 0.

#### Scenario: Clean exit verification
- **WHEN** installation completes
- **AND** exit code would be 0
- **THEN** verify all installed tools pass version check
- **AND** verify all configs are deployed
- **AND** verify shell integration blocks are present
- **IF** any verification fails, exit with code 2 (partial success)

### Requirement: Architecture detection
The system SHALL detect CPU architecture and map to download variants.

#### Scenario: Unsupported architecture
- **WHEN** architecture is not x86_64 or aarch64
- **THEN** exit with error message listing supported architectures

### Requirement: Latest version resolution
The system SHALL query GitHub API for latest stable releases and cache results.

#### Scenario: Fetch latest version
- **WHEN** installing a binary tool
- **THEN** query GitHub API for latest release
- **AND** cache result for 1 hour

#### Scenario: User override
- **WHEN** `~/.config/rice/version_overrides` contains `TOOL_VERSION=X.Y.Z`
- **THEN** use specified version instead of latest

### Requirement: Checksum verification
The system SHALL verify downloaded binaries against upstream-published checksums.

#### Scenario: Checksum success
- **WHEN** downloaded file checksum matches upstream
- **THEN** proceed with installation

#### Scenario: Checksum failure
- **WHEN** checksum does not match
- **THEN** display security error with expected and actual values
- **AND** abort installation of that tool

#### Scenario: Checksum unavailable
- **WHEN** upstream does not publish checksums
- **THEN** fail installation with clear message

### Requirement: Download URL construction
The system SHALL construct download URLs from version and architecture.

#### Scenario: URL construction
- **WHEN** downloading a binary
- **THEN** construct URL from repo, version, and architecture

### Requirement: GitHub rate limit handling
The system SHALL implement retry with exponential backoff for GitHub API requests.

#### Scenario: Rate limit hit
- **WHEN** GitHub returns 403 rate limit
- **THEN** retry with exponential backoff
- **AND** if all retries fail, suggest setting GITHUB_TOKEN

### Requirement: Config marker comment
The system SHALL include marker comments in all rice-managed config files.

#### Scenario: Target doesn't exist
- **WHEN** deploying config and target file doesn't exist
- **THEN** copy rice config verbatim

#### Scenario: Target exists with rice marker
- **WHEN** deploying config and target has rice marker
- **THEN** overwrite entire file (rice owns it)

#### Scenario: Target exists without marker
- **WHEN** deploying config and target exists but lacks marker
- **THEN** backup to `~/.config/rice/backups/{filename}.{timestamp}`
- **AND** copy rice config
- **AND** log backup location

### Requirement: Shell integration blocks
The system SHALL use delimited blocks for shell integrations that can be replaced on update.

#### Scenario: Integration block format
- **WHEN** adding shell integration
- **THEN** wrap in `# >>> rice: {tool} >>>` and `# <<< rice: {tool} <<<`

#### Scenario: Update integration
- **WHEN** re-running rice with existing integration
- **THEN** replace entire block between markers

### Requirement: HTTPS enforcement
The system SHALL require HTTPS for all upstream installer URLs.

#### Scenario: HTTP rejection
- **WHEN** installer URL uses HTTP
- **THEN** fail with security error

### Requirement: Install prerequisites
The system SHALL install required prerequisites on fresh systems.

#### Scenario: Fresh system
- **GIVEN** a minimal Debian/Ubuntu installation
- **WHEN** rice installer runs
- **THEN** install: git, curl, sudo, build-essential, unzip, pkg-config, libssl-dev
- **AND** fail fast with clear error if apt-get is unavailable

### Requirement: Quiet package installation
The system SHALL suppress apt output unless RICE_VERBOSE is set.

#### Scenario: apt package installation
- **WHEN** installing packages via apt
- **THEN** use `apt-get -qq install` to suppress output
- **AND** show rice's own single-line status for each package
- **AND** if `RICE_VERBOSE=1`, use `apt-get install` (normal verbosity)

### Requirement: Install Rust toolchain
The system SHALL install rustup/cargo/rustc.

#### Scenario: Fresh installation
- **WHEN** rustup is not installed
- **THEN** fetch and run upstream installer from `sh.rustup.rs` with `-y` flag

#### Scenario: PATH configuration
- **WHEN** Rust is installed
- **THEN** ensure `~/.cargo/bin` is in PATH via zshrc

### Requirement: Install Go
The system SHALL install Go toolchain.

#### Scenario: Binary installation
- **WHEN** Go is not installed
- **THEN** download binary from `go.dev/dl/` for detected architecture
- **AND** install to `/usr/local/go`
- **AND** verify checksum before extraction

#### Scenario: PATH configuration
- **WHEN** Go is installed
- **THEN** ensure `/usr/local/go/bin` and `~/go/bin` are in PATH via zshrc

### Requirement: Install bun
The system SHALL install bun as a fast JS/TS runtime.

#### Scenario: Fresh installation
- **WHEN** bun is not installed
- **THEN** fetch and run upstream installer from `bun.sh/install`

### Requirement: Install uv
The system SHALL install uv as a fast Python package manager.

#### Scenario: Fresh installation
- **WHEN** uv is not installed
- **THEN** fetch and run upstream installer from `astral.sh/uv/install.sh`

### Requirement: Install zsh
The system SHALL install zsh as the primary shell.

#### Scenario: Fresh installation
- **WHEN** zsh is not installed
- **THEN** install via package manager (`apt-get install -y zsh`)

#### Scenario: Already installed
- **WHEN** zsh is already installed
- **THEN** skip installation and log success

### Requirement: Configure oh-my-zsh
The system SHALL install oh-my-zsh as the plugin framework.

#### Scenario: Fresh installation
- **WHEN** oh-my-zsh is not installed
- **THEN** fetch and run the upstream installer

#### Scenario: Already installed
- **WHEN** `~/.oh-my-zsh` directory exists
- **THEN** skip installation and log success

### Requirement: Configure powerlevel10k prompt
The system SHALL install powerlevel10k as the prompt theme.

#### Scenario: Fresh installation
- **WHEN** powerlevel10k is not installed
- **THEN** git clone `romkatv/powerlevel10k` to `~/.oh-my-zsh/custom/themes/powerlevel10k`

#### Scenario: Deploy configuration
- **WHEN** powerlevel10k is installed
- **THEN** deploy `p10k.zsh` to `~/.p10k.zsh`
- **AND** set `POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true`
- **AND** use ASCII-compatible "lean" preset for headless servers

#### Scenario: Font notice
- **WHEN** installation completes
- **THEN** log in summary: "Install a Nerd Font on your terminal client for best experience"

### Requirement: Install zsh plugins
The system SHALL install zsh-autosuggestions and zsh-syntax-highlighting.

#### Scenario: Install autosuggestions
- **WHEN** zsh-autosuggestions is not installed
- **THEN** git clone to `~/.oh-my-zsh/custom/plugins/zsh-autosuggestions`

#### Scenario: Install syntax highlighting
- **WHEN** zsh-syntax-highlighting is not installed
- **THEN** git clone to `~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting`

### Requirement: Install direnv
The system SHALL install direnv for directory-specific environment variables.

#### Scenario: Fresh installation
- **WHEN** direnv is not installed
- **THEN** install via package manager (`apt-get install -y direnv`)

#### Scenario: Shell integration
- **WHEN** direnv is installed
- **THEN** add shell integration block to zshrc

### Requirement: Change default shell
The system SHALL change the user's default shell to zsh unless `RICE_SKIP_SHELL_CHANGE=1`.

#### Scenario: Change shell
- **WHEN** default shell is not zsh and `RICE_SKIP_SHELL_CHANGE` is not set
- **THEN** run `chsh -s $(command -v zsh)`

#### Scenario: Skip shell change
- **WHEN** `RICE_SKIP_SHELL_CHANGE=1` is set
- **THEN** skip shell change and log notice

### Requirement: Handle Debian binary name aliases
The system SHALL handle Debian packages that install binaries with different names.

#### Scenario: bat/batcat
- **WHEN** checking if bat is installed
- **THEN** check for both `bat` and `batcat`
- **AND** if `batcat` exists but `bat` doesn't, create symlink

#### Scenario: fd/fdfind
- **WHEN** checking if fd is installed
- **THEN** check for both `fd` and `fdfind`
- **AND** if `fdfind` exists but `fd` doesn't, create symlink

### Requirement: Install lsd
The system SHALL install lsd as a modern ls replacement.

#### Scenario: APT installation (preferred)
- **WHEN** running on Debian and lsd is not installed
- **THEN** attempt `apt-get install -y lsd`

#### Scenario: Cargo fallback
- **WHEN** lsd is not available via apt
- **THEN** install via `cargo install lsd`

### Requirement: Install bat
The system SHALL install bat as a modern cat replacement with syntax highlighting.

#### Scenario: APT installation (preferred)
- **WHEN** running on Debian and bat is not installed
- **THEN** attempt `apt-get install -y bat`

#### Scenario: Debian symlink
- **WHEN** `batcat` exists but `bat` does not
- **THEN** create symlink to `~/.local/bin/bat`

#### Scenario: Cargo fallback
- **WHEN** bat is not available via apt and symlink not possible
- **THEN** install via `cargo install bat`

### Requirement: Install ripgrep
The system SHALL install ripgrep as a modern grep replacement.

#### Scenario: Fresh installation
- **WHEN** ripgrep is not installed
- **THEN** install via `apt-get install -y ripgrep`

#### Scenario: Already installed
- **WHEN** `rg` command exists
- **THEN** skip installation and log success

### Requirement: Install fd
The system SHALL install fd as a modern find replacement.

#### Scenario: APT installation (preferred)
- **WHEN** running on Debian and fd is not installed
- **THEN** attempt `apt-get install -y fd-find`

#### Scenario: Debian symlink
- **WHEN** `fdfind` exists but `fd` does not
- **THEN** create symlink to `~/.local/bin/fd`

#### Scenario: Cargo fallback
- **WHEN** fd-find is not available via apt and symlink not possible
- **THEN** install via `cargo install fd-find`

### Requirement: Install fzf
The system SHALL install fzf as a fuzzy finder.

#### Scenario: Fresh installation
- **WHEN** fzf is not installed
- **THEN** install via `apt-get install -y fzf`

### Requirement: Install zoxide
The system SHALL install zoxide as a smarter cd replacement with frecency.

#### Scenario: Fresh installation
- **WHEN** zoxide is not installed
- **THEN** fetch and run upstream installer

#### Scenario: Shell integration
- **WHEN** zoxide is installed
- **THEN** add shell integration block to zshrc

### Requirement: Install atuin
The system SHALL install atuin for enhanced shell history with search.

#### Scenario: Fresh installation
- **WHEN** atuin is not installed
- **THEN** fetch and run upstream installer from `setup.atuin.sh`

#### Scenario: Shell integration
- **WHEN** atuin is installed
- **THEN** add shell integration block to zshrc

### Requirement: Install jq
The system SHALL install jq as a JSON processor.

#### Scenario: Fresh installation
- **WHEN** jq is not installed
- **THEN** install via `apt-get install -y jq`

### Requirement: Install ast-grep
The system SHALL install ast-grep for structural code search.

#### Scenario: Cargo installation
- **WHEN** ast-grep is not installed
- **THEN** install via `cargo install ast-grep`

### Requirement: Install tmux
The system SHALL install tmux as a terminal multiplexer.

#### Scenario: Fresh installation
- **WHEN** tmux is not installed
- **THEN** install via `apt-get install -y tmux`

#### Scenario: Deploy configuration
- **WHEN** tmux is installed
- **THEN** deploy `tmux.conf` to `~/.config/rice/tmux.conf`
- **AND** create symlink: `~/.tmux.conf` → `~/.config/rice/tmux.conf`

### Requirement: Install helix
The system SHALL install helix as the modal text editor.

#### Scenario: Binary installation
- **WHEN** helix is not installed
- **THEN** download binary from GitHub releases for detected architecture
- **AND** verify checksum
- **AND** install to `~/.local/bin/hx`

#### Scenario: Deploy configuration
- **WHEN** helix is installed
- **THEN** deploy `helix/config.toml` to `~/.config/helix/config.toml`

### Requirement: Install lazygit
The system SHALL install lazygit as a Git TUI.

#### Scenario: Binary installation
- **WHEN** lazygit is not installed
- **THEN** download binary from GitHub releases for detected architecture
- **AND** verify checksum
- **AND** install to `~/.local/bin/lazygit`

### Requirement: Install delta
The system SHALL install delta for beautiful git diffs.

#### Scenario: Binary installation
- **WHEN** delta is not installed
- **THEN** download binary from GitHub releases for detected architecture
- **AND** verify checksum
- **AND** install to `~/.local/bin/delta`

#### Scenario: Git configuration
- **WHEN** delta is installed
- **THEN** deploy git config to `~/.config/rice/gitconfig`
- **AND** ensure `~/.gitconfig` includes rice gitconfig

### Requirement: Install GitHub CLI
The system SHALL install gh for GitHub integration.

#### Scenario: Fresh installation
- **WHEN** gh is not installed
- **THEN** install via `apt-get install -y gh`

### Requirement: Install git-lfs
The system SHALL install git-lfs for large file support.

#### Scenario: Fresh installation
- **WHEN** git-lfs is not installed
- **THEN** install via `apt-get install -y git-lfs`

### Requirement: Install opencode
The system SHALL install opencode as the AI coding assistant.

#### Scenario: Go install
- **WHEN** opencode is not installed
- **THEN** install via `go install github.com/sst/opencode@latest`

### Requirement: Install lf
The system SHALL install lf as a terminal file manager.

#### Scenario: Binary installation
- **WHEN** lf is not installed
- **THEN** download binary from GitHub releases for detected architecture
- **AND** verify checksum
- **AND** install to `~/.local/bin/lf`

#### Scenario: Deploy configuration
- **WHEN** lf is installed
- **THEN** deploy `lf/lfrc` to `~/.config/lf/lfrc`

### Requirement: Install tree
The system SHALL install tree for directory visualization.

#### Scenario: Fresh installation
- **WHEN** tree is not installed
- **THEN** install via `apt-get install -y tree`

### Requirement: Install trash-cli
The system SHALL install trash-cli for safe file deletion.

#### Scenario: Fresh installation
- **WHEN** trash-cli is not installed
- **THEN** install via `apt-get install -y trash-cli`

### Requirement: Install atool
The system SHALL install atool for universal archive handling.

#### Scenario: Fresh installation
- **WHEN** atool is not installed
- **THEN** install via `apt-get install -y atool`

### Requirement: Install p7zip
The system SHALL install p7zip for 7-zip archive support.

#### Scenario: Fresh installation
- **WHEN** p7zip is not installed
- **THEN** install via `apt-get install -y p7zip-full`

### Requirement: Install rsync
The system SHALL install rsync for fast file synchronization.

#### Scenario: Fresh installation
- **WHEN** rsync is not installed
- **THEN** install via `apt-get install -y rsync`

### Requirement: Install lsof
The system SHALL install lsof for debugging open files and ports.

#### Scenario: Fresh installation
- **WHEN** lsof is not installed
- **THEN** install via `apt-get install -y lsof`

### Requirement: Install dnsutils
The system SHALL install dnsutils for DNS debugging.

#### Scenario: Fresh installation
- **WHEN** dnsutils is not installed
- **THEN** install via `apt-get install -y dnsutils`

### Requirement: Install netcat
The system SHALL install netcat for network debugging.

#### Scenario: Fresh installation
- **WHEN** netcat is not installed
- **THEN** install via `apt-get install -y netcat-openbsd`

### Requirement: Install strace
The system SHALL install strace for syscall tracing.

#### Scenario: Fresh installation
- **WHEN** strace is not installed
- **THEN** install via `apt-get install -y strace`

### Requirement: Install htop
The system SHALL install htop for interactive process viewing.

#### Scenario: Fresh installation
- **WHEN** htop is not installed
- **THEN** install via `apt-get install -y htop`

### Requirement: Install btop
The system SHALL install btop as a modern resource monitor (if available).

#### Scenario: Fresh installation
- **WHEN** btop is not installed and available in repos (Debian 12+, Ubuntu 22.04+)
- **THEN** install via `apt-get install -y btop`

#### Scenario: Unavailable
- **WHEN** btop is not in repos
- **THEN** log: `✓ btop (unavailable, htop installed)`
- **AND** continue (htop meets the need)

### Requirement: Install ncdu
The system SHALL install ncdu for disk usage analysis.

#### Scenario: Fresh installation
- **WHEN** ncdu is not installed
- **THEN** install via `apt-get install -y ncdu`

### Requirement: Install watch
The system SHALL install watch for repeated command execution.

#### Scenario: Fresh installation
- **WHEN** watch is not installed
- **THEN** install via `apt-get install -y procps` (provides watch)

### Requirement: Install Tailscale
The system SHALL install Tailscale for zero-config VPN.

#### Scenario: Fresh installation
- **WHEN** Tailscale is not installed
- **THEN** fetch and run upstream installer from `tailscale.com/install.sh`

#### Scenario: Service status
- **WHEN** Tailscale is installed
- **THEN** log instruction to run `tailscale up` for authentication

### Requirement: Create config directory
The system SHALL create `~/.config/rice/` for all rice-managed configuration.

#### Scenario: Directory creation
- **WHEN** `~/.config/rice/` does not exist
- **THEN** create the directory with standard permissions
- **AND** create `~/.config/rice/backups/` for config backups

### Requirement: Deploy shell configuration
The system SHALL deploy zshrc to `~/.config/rice/zshrc`.

#### Scenario: Fresh deployment
- **WHEN** configuration does not exist
- **THEN** copy `configs/zshrc` to `~/.config/rice/zshrc`

#### Scenario: Source from .zshrc
- **WHEN** configuration is deployed
- **THEN** ensure `~/.zshrc` sources `~/.config/rice/zshrc`

#### Scenario: Local customizations
- **WHEN** `~/.zshrc.local` exists
- **THEN** source it at end of zshrc for user customizations

### Requirement: Deploy aliases
The system SHALL deploy shell aliases to `~/.config/rice/aliases.sh`.

#### Scenario: Standard aliases
- **WHEN** aliases are deployed
- **THEN** include aliases for: `ls` → `lsd`, `cat` → `bat`, `grep` → `rg`, `vim` → `hx`, `lg` → `lazygit`

### Requirement: Verify all tools
The system SHALL verify all installed tools pass version checks.

#### Scenario: Verification list
- **WHEN** verifying tools
- **THEN** check: zsh, cargo, go, bun, uv, rg, fd, bat, fzf, zoxide, atuin, hx, lazygit, delta, lf, jq, sg, opencode

### Requirement: Print summary on completion
The system SHALL display a summary box on installation completion.

#### Scenario: Successful installation
- **WHEN** all components install successfully
- **THEN** display summary box with component count, elapsed time, and next steps

#### Scenario: Partial success (some failures)
- **WHEN** some components failed
- **THEN** display summary with failure count and reasons
- **AND** suggest re-running rice

### Requirement: Welcome message on first shell
The system SHALL display a welcome message on first shell session after install.

#### Scenario: First zsh session after install
- **WHEN** user runs `exec zsh` after first rice install
- **AND** `~/.config/rice/.welcomed` does not exist
- **THEN** display welcome message
- **AND** create `~/.config/rice/.welcomed` marker file

### Requirement: rice doctor command
The system SHALL provide a diagnostic command to check installation health.

#### Scenario: Health check
- **WHEN** running `rice doctor`
- **THEN** check all prerequisites, runtimes, shell, tools, and configs
- **AND** report pass/fail for each
- **AND** suggest `rice` to repair

#### Scenario: Perfect health
- **WHEN** all checks pass
- **THEN** display "All N checks passed. Your environment is healthy."

### Requirement: rice status command
The system SHALL provide a status command showing installed components.

#### Scenario: Status display
- **WHEN** running `rice status`
- **THEN** show state file location and last run time
- **AND** list managed configs
- **AND** list installed tools with versions and methods

### Requirement: Self-update
The system SHALL provide an update command that fetches and runs the latest installer.

#### Scenario: Update flow
- **WHEN** running `rice update`
- **THEN** fetch latest installer from upstream
- **AND** execute new version

### Requirement: Tool updates
The system SHALL update tools to latest versions when re-run.

#### Scenario: Version check
- **WHEN** re-running rice
- **THEN** compare installed version to latest release
- **AND** update if newer available

### Requirement: Config updates
The system SHALL overwrite rice-managed configs and preserve user customizations.

#### Scenario: Config overwrite
- **WHEN** re-running rice with existing rice-managed config
- **THEN** overwrite with latest version

### Requirement: Support unattended installation
The system SHALL support fully unattended installation via `RICE_YES=1`.

#### Scenario: Skip prompts
- **WHEN** `RICE_YES=1` is set
- **THEN** assume "yes" for all prompts

#### Scenario: Upstream installers
- **WHEN** running upstream installers with `RICE_YES=1`
- **THEN** pass appropriate non-interactive flags (`-y`, `--yes`, etc.)

---

## Version Policy

### Default: Latest stable
rice installs the latest stable release of each binary tool. This is
self-maintaining—users always get current versions without maintainer
intervention.

### Security model
- Checksums fetched from upstream release assets (not maintained by rice)
- Verification happens against publisher's own checksums
- If upstream doesn't publish checksums, installation fails (safe default)

### User overrides
Create `~/.config/rice/version_overrides` to pin specific versions:
```
HELIX_VERSION=25.01
LAZYGIT_VERSION=0.44.1
```
Pinned versions still verify against upstream checksums for that version.

### apt-installed tools
rice does not manage apt package versions. Run `apt upgrade` separately.

---

## Environment Variables

The installer respects:
- `RICE_YES=1` — Skip all prompts (for automation)
- `RICE_VERBOSE=1` — Show detailed output
- `RICE_SKIP_SHELL_CHANGE=1` — Don't change default shell to zsh
- `GITHUB_TOKEN` — Authenticate GitHub API requests (avoids rate limits)
