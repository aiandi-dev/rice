#!/usr/bin/env bash
# rice package manager abstraction
# Provides quiet installation with rice-style status output

# Track if apt has been updated this session
APT_UPDATED=false

# Ensure apt cache is fresh (once per session)
apt_ensure_updated() {
  if [[ "$APT_UPDATED" == "true" ]]; then
    return 0
  fi

  log_detail "Updating apt cache..."

  if [[ "${RICE_VERBOSE:-0}" == "1" ]]; then
    $RICE_SUDO apt-get update
  else
    $RICE_SUDO apt-get update -qq 2>/dev/null
  fi

  APT_UPDATED=true
}

# Check if a package is installed via apt
apt_is_installed() {
  local package="$1"
  dpkg -l "$package" 2>/dev/null | grep -q "^ii"
}

# Check if a package is available in apt repos
apt_is_available() {
  local package="$1"
  apt-cache show "$package" &>/dev/null
}

# Install a package via apt
# Usage: apt_install "package" ["display_name"]
apt_install() {
  local package="$1"
  local display_name="${2:-$package}"

  # Check if already installed
  if apt_is_installed "$package"; then
    local version
    version=$(dpkg -l "$package" 2>/dev/null | grep "^ii" | awk '{print $3}' | cut -d- -f1 | cut -d+ -f1)
    log_ok "$display_name" "$version" "skipped"
    return 0
  fi

  # Ensure apt is updated
  apt_ensure_updated

  # Check if package is available
  if ! apt_is_available "$package"; then
    log_detail "Package $package not available in apt"
    return 1
  fi

  log_installing "$display_name"

  local apt_args=("-y")
  if [[ "${RICE_VERBOSE:-0}" != "1" ]]; then
    apt_args+=("-qq")
  fi

  if $RICE_SUDO apt-get install "${apt_args[@]}" "$package" 2>/dev/null; then
    local version
    version=$(dpkg -l "$package" 2>/dev/null | grep "^ii" | awk '{print $3}' | cut -d- -f1 | cut -d+ -f1)
    log_ok "$display_name" "$version"
    state_record_tool "$display_name" "$version" "apt"
    return 0
  else
    log_error "Failed to install $display_name via apt"
    state_record_tool_failed "$display_name" "apt install failed"
    return 1
  fi
}

# Install multiple packages at once
# Usage: apt_install_many "pkg1" "pkg2" "pkg3"
apt_install_many() {
  local packages=("$@")

  # Filter to only packages not yet installed
  local to_install=()
  for pkg in "${packages[@]}"; do
    if ! apt_is_installed "$pkg"; then
      to_install+=("$pkg")
    fi
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    return 0
  fi

  apt_ensure_updated

  local apt_args=("-y")
  if [[ "${RICE_VERBOSE:-0}" != "1" ]]; then
    apt_args+=("-qq")
  fi

  $RICE_SUDO apt-get install "${apt_args[@]}" "${to_install[@]}" 2>/dev/null
}

# Install a package, handling command/package name differences
# Usage: pkg_install "command_name" "package_name" ["display_name"]
pkg_install() {
  local cmd="$1"
  local package="$2"
  local display_name="${3:-$cmd}"

  # Check if command already exists
  if command -v "$cmd" &>/dev/null; then
    local version
    version=$(get_installed_version "$cmd" 2>/dev/null || echo "installed")
    log_ok "$display_name" "$version" "skipped"
    return 0
  fi

  case "$RICE_PKG_MANAGER" in
    apt)
      apt_install "$package" "$display_name"
      ;;
    dnf)
      dnf_install "$package" "$display_name"
      ;;
    pacman)
      pacman_install "$package" "$display_name"
      ;;
    brew)
      brew_install "$package" "$display_name"
      ;;
    *)
      log_error "No supported package manager found"
      return 1
      ;;
  esac
}

# DNF wrapper (Fedora)
dnf_install() {
  local package="$1"
  local display_name="${2:-$package}"

  if rpm -q "$package" &>/dev/null; then
    log_ok "$display_name" "" "skipped"
    return 0
  fi

  log_installing "$display_name"

  local dnf_args=("-y")
  if [[ "${RICE_VERBOSE:-0}" != "1" ]]; then
    dnf_args+=("-q")
  fi

  if $RICE_SUDO dnf install "${dnf_args[@]}" "$package"; then
    log_ok "$display_name"
    state_record_tool "$display_name" "" "dnf"
    return 0
  else
    log_error "Failed to install $display_name via dnf"
    return 1
  fi
}

# Pacman wrapper (Arch)
pacman_install() {
  local package="$1"
  local display_name="${2:-$package}"

  if pacman -Qi "$package" &>/dev/null; then
    log_ok "$display_name" "" "skipped"
    return 0
  fi

  log_installing "$display_name"

  local pacman_args=("--noconfirm")
  if [[ "${RICE_VERBOSE:-0}" != "1" ]]; then
    pacman_args+=("-q")
  fi

  if $RICE_SUDO pacman -S "${pacman_args[@]}" "$package"; then
    log_ok "$display_name"
    state_record_tool "$display_name" "" "pacman"
    return 0
  else
    log_error "Failed to install $display_name via pacman"
    return 1
  fi
}

# Homebrew wrapper (macOS)
brew_install() {
  local package="$1"
  local display_name="${2:-$package}"

  if brew list "$package" &>/dev/null; then
    log_ok "$display_name" "" "skipped"
    return 0
  fi

  log_installing "$display_name"

  local brew_args=()
  if [[ "${RICE_VERBOSE:-0}" != "1" ]]; then
    brew_args+=("-q")
  fi

  if brew install "${brew_args[@]}" "$package"; then
    log_ok "$display_name"
    state_record_tool "$display_name" "" "brew"
    return 0
  else
    log_error "Failed to install $display_name via brew"
    return 1
  fi
}

# Handle Debian binary name aliases (bat/batcat, fd/fdfind)
# Usage: ensure_alias "preferred_cmd" "alternate_cmd"
ensure_alias() {
  local preferred="$1"
  local alternate="$2"

  # If preferred exists, nothing to do
  if command -v "$preferred" &>/dev/null; then
    return 0
  fi

  # If alternate exists, create symlink
  if command -v "$alternate" &>/dev/null; then
    local alt_path
    alt_path=$(command -v "$alternate")

    # Ensure ~/.local/bin exists
    mkdir -p "${HOME}/.local/bin"

    # Create symlink
    ln -sf "$alt_path" "${HOME}/.local/bin/${preferred}"
    log_detail "Created symlink: $preferred -> $alt_path"
    return 0
  fi

  return 1
}
