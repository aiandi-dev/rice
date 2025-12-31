#!/usr/bin/env bash
# rice OS and architecture detection

# Detect operating system
# Sets: RICE_OS (debian, ubuntu, fedora, arch, macos)
detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    case "${ID:-}" in
      debian)
        RICE_OS="debian"
        RICE_OS_VERSION="${VERSION_ID:-unknown}"
        ;;
      ubuntu)
        RICE_OS="ubuntu"
        RICE_OS_VERSION="${VERSION_ID:-unknown}"
        ;;
      fedora)
        RICE_OS="fedora"
        RICE_OS_VERSION="${VERSION_ID:-unknown}"
        ;;
      arch|archlinux)
        RICE_OS="arch"
        RICE_OS_VERSION="rolling"
        ;;
      *)
        # Check for Debian-based distros
        if [[ "${ID_LIKE:-}" == *"debian"* ]]; then
          RICE_OS="debian"
          RICE_OS_VERSION="${VERSION_ID:-unknown}"
        else
          RICE_OS="unknown"
          RICE_OS_VERSION="unknown"
        fi
        ;;
    esac
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    RICE_OS="macos"
    RICE_OS_VERSION="$(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
  else
    RICE_OS="unknown"
    RICE_OS_VERSION="unknown"
  fi

  export RICE_OS RICE_OS_VERSION
}

# Detect CPU architecture
# Sets: RICE_ARCH (x86_64, aarch64)
# Sets: RICE_ARCH_ALT (amd64, arm64) - alternate naming for some tools
detect_arch() {
  local machine
  machine="$(uname -m)"

  case "$machine" in
    x86_64|amd64)
      RICE_ARCH="x86_64"
      RICE_ARCH_ALT="amd64"
      RICE_ARCH_GO="amd64"
      ;;
    aarch64|arm64)
      RICE_ARCH="aarch64"
      RICE_ARCH_ALT="arm64"
      RICE_ARCH_GO="arm64"
      ;;
    *)
      log_error "Unsupported architecture: $machine"
      log_error "rice supports: x86_64 (amd64), aarch64 (arm64)"
      return 1
      ;;
  esac

  export RICE_ARCH RICE_ARCH_ALT RICE_ARCH_GO
}

# Detect if running as root
detect_privileges() {
  if [[ $EUID -eq 0 ]]; then
    RICE_IS_ROOT=true
    RICE_SUDO=""
  else
    RICE_IS_ROOT=false
    if command -v sudo &>/dev/null; then
      RICE_SUDO="sudo"
    else
      log_error "Not running as root and sudo is not available"
      return 1
    fi
  fi

  export RICE_IS_ROOT RICE_SUDO
}

# Check if package manager is available
detect_package_manager() {
  if command -v apt-get &>/dev/null; then
    RICE_PKG_MANAGER="apt"
  elif command -v dnf &>/dev/null; then
    RICE_PKG_MANAGER="dnf"
  elif command -v pacman &>/dev/null; then
    RICE_PKG_MANAGER="pacman"
  elif command -v brew &>/dev/null; then
    RICE_PKG_MANAGER="brew"
  else
    RICE_PKG_MANAGER="none"
  fi

  export RICE_PKG_MANAGER
}

# Run all detection functions
detect_all() {
  detect_os
  detect_arch || return 1
  detect_privileges || return 1
  detect_package_manager

  log_detail "OS: $RICE_OS $RICE_OS_VERSION"
  log_detail "Arch: $RICE_ARCH ($RICE_ARCH_ALT)"
  log_detail "Package manager: $RICE_PKG_MANAGER"
  log_detail "Root: $RICE_IS_ROOT"
}

# Check if OS is supported
check_supported_os() {
  case "$RICE_OS" in
    debian|ubuntu)
      return 0
      ;;
    fedora|arch|macos)
      log_warn "OS '$RICE_OS' is planned but not fully tested"
      return 0
      ;;
    *)
      log_error "Unsupported OS: $RICE_OS"
      log_error "rice currently supports: Debian, Ubuntu"
      log_error "Planned: Fedora, Arch, macOS"
      return 1
      ;;
  esac
}
