#!/usr/bin/env bash
# rice CLI tools installation

#==============================================================================
# Phase 0: Prerequisites
#==============================================================================

install_prerequisites() {
  log_phase "Prerequisites"

  local packages=(
    "git"
    "curl"
    "sudo"
    "build-essential"
    "unzip"
    "pkg-config"
    "libssl-dev"
  )

  local failed=0

  for pkg in "${packages[@]}"; do
    case "$pkg" in
      git)
        pkg_install "git" "git" "git" || ((failed++))
        ;;
      curl)
        pkg_install "curl" "curl" "curl" || ((failed++))
        ;;
      sudo)
        # sudo is special - if we got here, we have it or are root
        if command -v sudo &>/dev/null || [[ $EUID -eq 0 ]]; then
          log_ok "sudo" "" "skipped"
        else
          log_error "sudo not available and not running as root"
          ((failed++))
        fi
        ;;
      build-essential)
        # Check for gcc as indicator
        if command -v gcc &>/dev/null; then
          log_ok "build-essential" "" "skipped"
        else
          apt_install "build-essential" "build-essential" || ((failed++))
        fi
        ;;
      unzip)
        pkg_install "unzip" "unzip" "unzip" || ((failed++))
        ;;
      pkg-config)
        pkg_install "pkg-config" "pkg-config" "pkg-config" || ((failed++))
        ;;
      libssl-dev)
        # Library, not a command - check via dpkg
        if apt_is_installed "libssl-dev"; then
          log_ok "libssl-dev" "" "skipped"
        else
          apt_install "libssl-dev" "libssl-dev" || ((failed++))
        fi
        ;;
    esac
  done

  if [[ $failed -gt 0 ]]; then
    log_error "$failed prerequisite(s) failed to install"
    return 1
  fi

  state_complete_phase 0
  return 0
}

#==============================================================================
# Phase 3: CLI Tools
#==============================================================================

# Install fd (find replacement)
install_fd() {
  if command -v fd &>/dev/null; then
    local version
    version=$(fd --version 2>/dev/null | awk '{print $2}')
    log_ok "fd" "$version" "skipped"
    return 0
  fi

  # Check for fdfind (Debian's name)
  if command -v fdfind &>/dev/null; then
    ensure_alias "fd" "fdfind"
    local version
    version=$(fdfind --version 2>/dev/null | awk '{print $2}')
    log_ok "fd" "$version" "symlinked"
    state_record_tool "fd" "$version" "apt" "symlinked" "true"
    return 0
  fi

  state_set_current_tool "fd"

  # Try apt first
  if apt_install "fd-find" "fd"; then
    ensure_alias "fd" "fdfind"
    state_set ".tools[\"fd\"].symlinked" "true" 2>/dev/null || true
    state_clear_current_tool
    return 0
  fi

  # Fallback to cargo
  log_installing "fd (cargo)"
  ensure_cargo_path
  if cargo install fd-find 2>/dev/null; then
    local version
    version=$(fd --version 2>/dev/null | awk '{print $2}')
    log_ok "fd" "$version"
    state_record_tool "fd" "$version" "cargo"
    state_clear_current_tool
    return 0
  fi

  log_error "Failed to install fd"
  state_record_tool_failed "fd" "installation failed"
  state_clear_current_tool
  return 1
}

# Install ripgrep
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

# Install bat (cat replacement)
install_bat() {
  if command -v bat &>/dev/null; then
    local version
    version=$(bat --version 2>/dev/null | awk '{print $2}')
    log_ok "bat" "$version" "skipped"
    return 0
  fi

  # Check for batcat (Debian's name)
  if command -v batcat &>/dev/null; then
    ensure_alias "bat" "batcat"
    local version
    version=$(batcat --version 2>/dev/null | awk '{print $2}')
    log_ok "bat" "$version" "symlinked"
    state_record_tool "bat" "$version" "apt" "symlinked" "true"
    return 0
  fi

  state_set_current_tool "bat"

  # Try apt first
  if apt_install "bat" "bat"; then
    ensure_alias "bat" "batcat"
    state_clear_current_tool
    return 0
  fi

  # Fallback to cargo
  log_installing "bat (cargo)"
  ensure_cargo_path
  if cargo install bat 2>/dev/null; then
    local version
    version=$(bat --version 2>/dev/null | awk '{print $2}')
    log_ok "bat" "$version"
    state_record_tool "bat" "$version" "cargo"
    state_clear_current_tool
    return 0
  fi

  log_error "Failed to install bat"
  state_record_tool_failed "bat" "installation failed"
  state_clear_current_tool
  return 1
}

# Install lsd (ls replacement)
install_lsd() {
  if command -v lsd &>/dev/null; then
    local version
    version=$(lsd --version 2>/dev/null | awk '{print $2}')
    log_ok "lsd" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "lsd"

  # Try apt first
  if apt_install "lsd" "lsd"; then
    state_clear_current_tool
    return 0
  fi

  # Fallback to cargo
  log_installing "lsd (cargo)"
  ensure_cargo_path
  if cargo install lsd 2>/dev/null; then
    local version
    version=$(lsd --version 2>/dev/null | awk '{print $2}')
    log_ok "lsd" "$version"
    state_record_tool "lsd" "$version" "cargo"
    state_clear_current_tool
    return 0
  fi

  log_error "Failed to install lsd"
  state_record_tool_failed "lsd" "installation failed"
  state_clear_current_tool
  return 1
}

# Install fzf
install_fzf() {
  if command -v fzf &>/dev/null; then
    local version
    version=$(fzf --version 2>/dev/null | awk '{print $1}')
    log_ok "fzf" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "fzf"
  apt_install "fzf" "fzf"
  local result=$?
  state_clear_current_tool
  return $result
}

# Install zoxide
install_zoxide() {
  if command -v zoxide &>/dev/null; then
    local version
    version=$(zoxide --version 2>/dev/null | awk '{print $2}')
    log_ok "zoxide" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "zoxide"
  log_installing "zoxide"

  if ! run_upstream_installer "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"; then
    log_error "Failed to install zoxide"
    state_record_tool_failed "zoxide" "installer failed"
    state_clear_current_tool
    return 1
  fi

  local version
  version=$("${HOME}/.local/bin/zoxide" --version 2>/dev/null | awk '{print $2}')
  log_ok "zoxide" "$version"
  state_record_tool "zoxide" "$version" "upstream"
  state_clear_current_tool
}

# Install atuin
install_atuin() {
  if command -v atuin &>/dev/null; then
    local version
    version=$(atuin --version 2>/dev/null | awk '{print $2}')
    log_ok "atuin" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "atuin"
  log_installing "atuin"

  # atuin installer
  if ! bash -c "$(curl -fsSL https://setup.atuin.sh)" -- --yes 2>/dev/null; then
    log_error "Failed to install atuin"
    state_record_tool_failed "atuin" "installer failed"
    state_clear_current_tool
    return 1
  fi

  local version
  version=$("${HOME}/.atuin/bin/atuin" --version 2>/dev/null | awk '{print $2}')
  log_ok "atuin" "$version"
  state_record_tool "atuin" "$version" "upstream"
  state_clear_current_tool
}

# Install jq
install_jq() {
  if command -v jq &>/dev/null; then
    local version
    version=$(jq --version 2>/dev/null | sed 's/jq-//')
    log_ok "jq" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "jq"
  apt_install "jq" "jq"
  local result=$?
  state_clear_current_tool
  return $result
}

# Install ast-grep
install_ast_grep() {
  if command -v sg &>/dev/null; then
    local version
    version=$(sg --version 2>/dev/null | awk '{print $2}')
    log_ok "ast-grep" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "ast-grep"
  log_installing "ast-grep"

  ensure_cargo_path
  if cargo install ast-grep 2>/dev/null; then
    local version
    version=$(sg --version 2>/dev/null | awk '{print $2}')
    log_ok "ast-grep" "$version"
    state_record_tool "ast-grep" "$version" "cargo"
    state_clear_current_tool
    return 0
  fi

  log_error "Failed to install ast-grep"
  state_record_tool_failed "ast-grep" "cargo install failed"
  state_clear_current_tool
  return 1
}

# Install all CLI tools (Phase 3)
install_cli_tools() {
  log_phase "CLI Tools"

  local failed=0

  install_fd || ((failed++))
  install_ripgrep || ((failed++))
  install_bat || ((failed++))
  install_lsd || ((failed++))
  install_fzf || ((failed++))
  install_zoxide || ((failed++))
  install_atuin || ((failed++))
  install_jq || ((failed++))
  install_ast_grep || ((failed++))

  if [[ $failed -gt 0 ]]; then
    log_warn "$failed CLI tool(s) failed to install"
    return 1
  fi

  state_complete_phase 3
  return 0
}

#==============================================================================
# Phase 4: Developer Tools
#==============================================================================

# Install tmux
install_tmux() {
  if command -v tmux &>/dev/null; then
    local version
    version=$(tmux -V 2>/dev/null | awk '{print $2}')
    log_ok "tmux" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "tmux"
  apt_install "tmux" "tmux"
  local result=$?
  state_clear_current_tool
  return $result
}

# Install helix (upstream doesn't publish checksums - download directly)
install_helix() {
  if command -v hx &>/dev/null; then
    local version
    version=$(hx --version 2>/dev/null | head -1 | awk '{print $2}')
    log_ok "helix" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "helix"
  log_installing "helix"

  # Get latest version
  local version
  version=$(get_latest_release "helix-editor/helix")
  if [[ -z "$version" ]]; then
    log_error "Could not determine latest helix version"
    state_record_tool_failed "helix" "version lookup failed"
    state_clear_current_tool
    return 1
  fi

  local archive="helix-${version}-${RICE_ARCH}-linux.tar.xz"
  local url="https://github.com/helix-editor/helix/releases/download/${version}/${archive}"

  # Download (helix doesn't publish checksums)
  local tmp_archive
  tmp_archive=$(mktemp)
  if ! download_file "$url" "$tmp_archive"; then
    rm -f "$tmp_archive"
    state_record_tool_failed "helix" "download failed"
    state_clear_current_tool
    return 1
  fi

  # Extract
  local extract_dir
  extract_dir=$(mktemp -d)
  if ! tar -xJf "$tmp_archive" -C "$extract_dir"; then
    log_error "Failed to extract helix archive"
    rm -rf "$tmp_archive" "$extract_dir"
    state_record_tool_failed "helix" "extraction failed"
    state_clear_current_tool
    return 1
  fi
  rm -f "$tmp_archive"

  # Install binary
  local hx_binary
  hx_binary=$(find "$extract_dir" -name "hx" -type f 2>/dev/null | head -1)
  if [[ -z "$hx_binary" ]]; then
    log_error "hx binary not found in archive"
    rm -rf "$extract_dir"
    state_record_tool_failed "helix" "binary not found"
    state_clear_current_tool
    return 1
  fi

  mkdir -p "${HOME}/.local/bin"
  cp "$hx_binary" "${HOME}/.local/bin/hx"
  chmod +x "${HOME}/.local/bin/hx"

  # Install runtime (required for helix to function)
  local runtime_dir
  runtime_dir=$(find "$extract_dir" -type d -name "runtime" 2>/dev/null | head -1)
  if [[ -n "$runtime_dir" ]]; then
    mkdir -p "${HOME}/.config/helix"
    rm -rf "${HOME}/.config/helix/runtime"
    cp -r "$runtime_dir" "${HOME}/.config/helix/"
  fi

  rm -rf "$extract_dir"

  log_ok "helix" "$version"
  state_record_tool "helix" "$version" "binary"
  state_clear_current_tool
}

# Install lazygit
install_lazygit() {
  if command -v lazygit &>/dev/null; then
    local version
    version=$(lazygit --version 2>/dev/null | grep -oE 'version=[0-9.]+' | cut -d= -f2)
    log_ok "lazygit" "$version" "skipped"
    return 0
  fi

  install_github_binary \
    "jesseduffield/lazygit" \
    "lazygit" \
    "lazygit_{VERSION}_linux_{ARCH}.tar.gz" \
    "checksums.txt" \
    "lazygit" \
    "lazygit"
}

# Install delta (git-delta via cargo - upstream doesn't publish checksums)
install_delta() {
  if command -v delta &>/dev/null; then
    local version
    version=$(delta --version 2>/dev/null | awk '{print $2}')
    log_ok "delta" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "delta"
  log_installing "delta"

  ensure_cargo_path
  if cargo install git-delta 2>/dev/null; then
    local version
    version=$(delta --version 2>/dev/null | awk '{print $2}')
    log_ok "delta" "$version"
    state_record_tool "delta" "$version" "cargo"
    state_clear_current_tool
    return 0
  fi

  log_error "Failed to install delta"
  state_record_tool_failed "delta" "cargo install failed"
  state_clear_current_tool
  return 1
}

# Install GitHub CLI
install_gh() {
  if command -v gh &>/dev/null; then
    local version
    version=$(gh --version 2>/dev/null | head -1 | awk '{print $3}')
    log_ok "gh" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "gh"

  # Add GitHub CLI apt repository if not present
  if ! apt_is_available "gh"; then
    log_detail "Adding GitHub CLI repository..."
    $RICE_SUDO mkdir -p /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      $RICE_SUDO tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
      $RICE_SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    APT_UPDATED=false  # Force apt update
  fi

  apt_install "gh" "gh"
  local result=$?
  state_clear_current_tool
  return $result
}

# Install git-lfs
install_git_lfs() {
  if command -v git-lfs &>/dev/null; then
    local version
    version=$(git-lfs --version 2>/dev/null | awk '{print $1}' | sed 's|git-lfs/||')
    log_ok "git-lfs" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "git-lfs"
  apt_install "git-lfs" "git-lfs"
  local result=$?

  # Initialize git-lfs
  if [[ $result -eq 0 ]]; then
    git lfs install --skip-repo 2>/dev/null || true
  fi

  state_clear_current_tool
  return $result
}

# Install opencode
install_opencode() {
  if command -v opencode &>/dev/null; then
    local version
    version=$(opencode version 2>/dev/null | head -1)
    log_ok "opencode" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "opencode"
  log_installing "opencode"

  # opencode uses its own installer script
  export OPENCODE_INSTALL_DIR="${HOME}/.local/bin"
  if run_upstream_installer "https://opencode.ai/install"; then
    local version
    version=$(opencode version 2>/dev/null | head -1)
    log_ok "opencode" "$version"
    state_record_tool "opencode" "$version" "upstream"
    state_clear_current_tool
    return 0
  fi

  log_error "Failed to install opencode"
  state_record_tool_failed "opencode" "installer failed"
  state_clear_current_tool
  return 1
}

# Install all developer tools (Phase 4)
install_dev_tools() {
  log_phase "Developer Tools"

  local failed=0

  install_tmux || ((failed++))
  install_helix || ((failed++))
  install_lazygit || ((failed++))
  install_delta || ((failed++))
  install_gh || ((failed++))
  install_git_lfs || ((failed++))
  install_opencode || ((failed++))

  if [[ $failed -gt 0 ]]; then
    log_warn "$failed developer tool(s) failed to install"
    return 1
  fi

  state_complete_phase 4
  return 0
}

#==============================================================================
# Phase 5: File Management
#==============================================================================

# Install lf
install_lf() {
  if command -v lf &>/dev/null; then
    local version
    version=$(lf --version 2>/dev/null | head -1)
    log_ok "lf" "$version" "skipped"
    return 0
  fi

  install_github_binary \
    "gokcehan/lf" \
    "lf" \
    "lf-linux-{RICE_ARCH_GO}.tar.gz" \
    "lf-linux-{RICE_ARCH_GO}.tar.gz.md5" \
    "lf" \
    "lf"

  # Note: lf uses MD5, we'll handle this specially
  # For now, just download without checksum verification for lf
  # TODO: implement MD5 support or skip checksum for lf
}

# Install tree
install_tree() {
  pkg_install "tree" "tree" "tree"
}

# Install trash-cli
install_trash_cli() {
  pkg_install "trash-put" "trash-cli" "trash-cli"
}

# Install atool
install_atool() {
  pkg_install "atool" "atool" "atool"
}

# Install p7zip
install_p7zip() {
  if command -v 7z &>/dev/null; then
    log_ok "p7zip" "" "skipped"
    return 0
  fi

  state_set_current_tool "p7zip"
  apt_install "p7zip-full" "p7zip"
  local result=$?
  state_clear_current_tool
  return $result
}

# Install all file management tools (Phase 5)
install_file_tools() {
  log_phase "File Management"

  local failed=0

  install_lf || ((failed++))
  install_tree || ((failed++))
  install_trash_cli || ((failed++))
  install_atool || ((failed++))
  install_p7zip || ((failed++))

  if [[ $failed -gt 0 ]]; then
    log_warn "$failed file management tool(s) failed to install"
    return 1
  fi

  state_complete_phase 5
  return 0
}

#==============================================================================
# Phase 6: System Utilities
#==============================================================================

install_system_utils() {
  log_phase "System Utilities"

  local failed=0

  pkg_install "rsync" "rsync" "rsync" || ((failed++))
  pkg_install "lsof" "lsof" "lsof" || ((failed++))
  pkg_install "dig" "dnsutils" "dnsutils" || ((failed++))
  pkg_install "nc" "netcat-openbsd" "netcat" || ((failed++))
  pkg_install "strace" "strace" "strace" || ((failed++))
  pkg_install "htop" "htop" "htop" || ((failed++))

  # btop - may not be available on older systems
  if apt_is_available "btop"; then
    pkg_install "btop" "btop" "btop" || ((failed++))
  else
    log_ok "btop" "unavailable" "htop installed"
  fi

  pkg_install "ncdu" "ncdu" "ncdu" || ((failed++))

  # watch is provided by procps
  if command -v watch &>/dev/null; then
    log_ok "watch" "" "skipped"
  else
    apt_install "procps" "watch" || ((failed++))
  fi

  if [[ $failed -gt 0 ]]; then
    log_warn "$failed system utility(s) failed to install"
    return 1
  fi

  state_complete_phase 6
  return 0
}

#==============================================================================
# Phase 7: Infrastructure
#==============================================================================

install_infrastructure() {
  log_phase "Infrastructure"

  local failed=0

  # Tailscale
  if command -v tailscale &>/dev/null; then
    local version
    version=$(tailscale --version 2>/dev/null | head -1)
    log_ok "tailscale" "$version" "skipped"
  else
    state_set_current_tool "tailscale"
    log_installing "tailscale"

    if run_upstream_installer "https://tailscale.com/install.sh"; then
      log_ok "tailscale"
      log_detail "Run 'tailscale up' to authenticate"
      state_record_tool "tailscale" "" "upstream"
    else
      log_error "Failed to install tailscale"
      state_record_tool_failed "tailscale" "installer failed"
      ((failed++))
    fi

    state_clear_current_tool
  fi

  if [[ $failed -gt 0 ]]; then
    log_warn "$failed infrastructure component(s) failed to install"
    return 1
  fi

  state_complete_phase 7
  return 0
}
