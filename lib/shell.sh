#!/usr/bin/env bash
# rice shell setup (zsh, oh-my-zsh, powerlevel10k, plugins)

# oh-my-zsh installation directory
OMZ_DIR="${HOME}/.oh-my-zsh"
OMZ_CUSTOM="${OMZ_DIR}/custom"

# Install zsh
install_zsh() {
  if command -v zsh &>/dev/null; then
    local version
    version=$(zsh --version 2>/dev/null | awk '{print $2}')
    log_ok "zsh" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "zsh"

  case "$RICE_PKG_MANAGER" in
    apt)
      apt_install "zsh" "zsh"
      ;;
    dnf)
      dnf_install "zsh" "zsh"
      ;;
    pacman)
      pacman_install "zsh" "zsh"
      ;;
    brew)
      brew_install "zsh" "zsh"
      ;;
    *)
      log_error "Cannot install zsh: no supported package manager"
      return 1
      ;;
  esac

  state_clear_current_tool
}

# Install oh-my-zsh
install_oh_my_zsh() {
  if [[ -d "$OMZ_DIR" ]]; then
    log_ok "oh-my-zsh" "" "skipped"
    return 0
  fi

  state_set_current_tool "oh-my-zsh"
  log_installing "oh-my-zsh"

  # oh-my-zsh installer with non-interactive flags
  local install_script
  install_script=$(mktemp)

  if ! curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" -o "$install_script"; then
    log_error "Failed to download oh-my-zsh installer"
    rm -f "$install_script"
    state_record_tool_failed "oh-my-zsh" "download failed"
    return 1
  fi

  # Run with RUNZSH=no to prevent launching zsh, CHSH=no to not change shell yet
  if ! RUNZSH=no CHSH=no sh "$install_script" --unattended; then
    log_error "Failed to install oh-my-zsh"
    rm -f "$install_script"
    state_record_tool_failed "oh-my-zsh" "installer failed"
    return 1
  fi

  rm -f "$install_script"

  log_ok "oh-my-zsh"
  state_record_tool "oh-my-zsh" "" "upstream"
  state_clear_current_tool
}

# Install powerlevel10k
install_powerlevel10k() {
  local p10k_dir="${OMZ_CUSTOM}/themes/powerlevel10k"

  if [[ -d "$p10k_dir" ]]; then
    log_ok "powerlevel10k" "" "skipped"
    return 0
  fi

  state_set_current_tool "powerlevel10k"
  log_installing "powerlevel10k"

  if ! git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" "$p10k_dir" 2>/dev/null; then
    log_error "Failed to clone powerlevel10k"
    state_record_tool_failed "powerlevel10k" "git clone failed"
    return 1
  fi

  log_ok "powerlevel10k"
  state_record_tool "powerlevel10k" "" "git"
  state_clear_current_tool
}

# Install zsh-autosuggestions plugin
install_zsh_autosuggestions() {
  local plugin_dir="${OMZ_CUSTOM}/plugins/zsh-autosuggestions"

  if [[ -d "$plugin_dir" ]]; then
    log_ok "zsh-autosuggestions" "" "skipped"
    return 0
  fi

  state_set_current_tool "zsh-autosuggestions"
  log_installing "zsh-autosuggestions"

  if ! git clone --depth=1 "https://github.com/zsh-users/zsh-autosuggestions.git" "$plugin_dir" 2>/dev/null; then
    log_error "Failed to clone zsh-autosuggestions"
    state_record_tool_failed "zsh-autosuggestions" "git clone failed"
    return 1
  fi

  log_ok "zsh-autosuggestions"
  state_record_tool "zsh-autosuggestions" "" "git"
  state_clear_current_tool
}

# Install zsh-syntax-highlighting plugin
install_zsh_syntax_highlighting() {
  local plugin_dir="${OMZ_CUSTOM}/plugins/zsh-syntax-highlighting"

  if [[ -d "$plugin_dir" ]]; then
    log_ok "zsh-syntax-highlighting" "" "skipped"
    return 0
  fi

  state_set_current_tool "zsh-syntax-highlighting"
  log_installing "zsh-syntax-highlighting"

  if ! git clone --depth=1 "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$plugin_dir" 2>/dev/null; then
    log_error "Failed to clone zsh-syntax-highlighting"
    state_record_tool_failed "zsh-syntax-highlighting" "git clone failed"
    return 1
  fi

  log_ok "zsh-syntax-highlighting"
  state_record_tool "zsh-syntax-highlighting" "" "git"
  state_clear_current_tool
}

# Install direnv
install_direnv() {
  if command -v direnv &>/dev/null; then
    local version
    version=$(direnv --version 2>/dev/null)
    log_ok "direnv" "$version" "skipped"
    return 0
  fi

  state_set_current_tool "direnv"

  case "$RICE_PKG_MANAGER" in
    apt)
      apt_install "direnv" "direnv"
      ;;
    dnf)
      dnf_install "direnv" "direnv"
      ;;
    pacman)
      pacman_install "direnv" "direnv"
      ;;
    brew)
      brew_install "direnv" "direnv"
      ;;
    *)
      log_error "Cannot install direnv: no supported package manager"
      return 1
      ;;
  esac

  state_clear_current_tool
}

# Change default shell to zsh
change_default_shell() {
  if [[ "${RICE_SKIP_SHELL_CHANGE:-0}" == "1" ]]; then
    log_detail "Skipping shell change (RICE_SKIP_SHELL_CHANGE=1)"
    return 0
  fi

  local current_shell
  current_shell=$(getent passwd "$USER" | cut -d: -f7)
  local zsh_path
  zsh_path=$(command -v zsh)

  if [[ "$current_shell" == "$zsh_path" ]]; then
    log_detail "Default shell is already zsh"
    return 0
  fi

  log_detail "Changing default shell to zsh..."

  if [[ "${RICE_YES:-0}" == "1" ]]; then
    # Non-interactive: use chsh directly
    if ! chsh -s "$zsh_path" 2>/dev/null; then
      # Try with sudo if regular chsh fails
      if ! $RICE_SUDO chsh -s "$zsh_path" "$USER" 2>/dev/null; then
        log_warn "Could not change default shell to zsh"
        log_detail "Run manually: chsh -s $zsh_path"
        return 1
      fi
    fi
  else
    # Interactive: chsh may prompt for password
    if ! chsh -s "$zsh_path"; then
      log_warn "Could not change default shell to zsh"
      log_detail "Run manually: chsh -s $zsh_path"
      return 1
    fi
  fi

  log_detail "Default shell changed to zsh"
}

# Install all shell components
install_shell() {
  log_phase "Shell"

  local failed=0

  install_zsh || ((failed++))
  install_oh_my_zsh || ((failed++))
  install_powerlevel10k || ((failed++))
  install_zsh_autosuggestions || ((failed++))
  install_zsh_syntax_highlighting || ((failed++))
  install_direnv || ((failed++))

  # Change default shell (don't count as failure if it doesn't work)
  change_default_shell || true

  if [[ $failed -gt 0 ]]; then
    log_warn "$failed shell component(s) failed to install"
    return 1
  fi

  state_complete_phase 2
  return 0
}
