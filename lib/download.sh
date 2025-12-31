#!/usr/bin/env bash
# rice binary download with checksum verification

# Download cache directory
RICE_DOWNLOAD_CACHE="${HOME}/.cache/rice/downloads"

# Ensure download cache exists
download_init() {
  mkdir -p "$RICE_DOWNLOAD_CACHE"
}

# Download a file with retry logic
# Usage: download_file "url" "output_path"
download_file() {
  local url="$1"
  local output="$2"
  local attempt=1
  local max_attempts=3

  # Enforce HTTPS
  if [[ "$url" == http://* ]]; then
    log_error "Security error: HTTP URLs are not allowed"
    log_error "URL must use HTTPS: $url"
    return 1
  fi

  while [[ $attempt -le $max_attempts ]]; do
    log_detail "Downloading: $url (attempt $attempt)"

    if curl -fsSL --connect-timeout 30 --max-time 300 -o "$output" "$url" 2>/dev/null; then
      return 0
    fi

    if [[ $attempt -lt $max_attempts ]]; then
      log_detail "Download failed, retrying in 2s..."
      sleep 2
    fi
    ((attempt++))
  done

  log_error_box "download" "failed" \
    "Could not download: $url" \
    "Check your internet connection" \
    "Try again in a few minutes" \
    "Check if the URL is accessible: curl -I '$url'"

  return 1
}

# Verify SHA256 checksum
# Usage: verify_checksum "file" "expected_checksum"
verify_checksum() {
  local file="$1"
  local expected="$2"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  local actual
  actual=$(sha256sum "$file" 2>/dev/null | awk '{print $1}')

  if [[ -z "$actual" ]]; then
    log_error "Could not compute checksum for: $file"
    return 1
  fi

  if [[ "$actual" != "$expected" ]]; then
    log_error_box "checksum" "verification failed" \
      "SHA256 mismatch for $(basename "$file")" \
      "Expected: $expected" \
      "Actual:   $actual" \
      "Remove the cached file and re-run rice" \
      "rm '$file' && rice"

    return 1
  fi

  log_detail "Checksum verified: $expected"
  return 0
}

# Download and verify a binary release
# Usage: download_binary "url" "checksum" "output_name"
# Returns path to downloaded file on stdout
download_binary() {
  local url="$1"
  local expected_checksum="$2"
  local output_name="$3"

  download_init

  local output_path="${RICE_DOWNLOAD_CACHE}/${output_name}"

  # Check if already cached with correct checksum
  if [[ -f "$output_path" ]]; then
    if verify_checksum "$output_path" "$expected_checksum" 2>/dev/null; then
      log_detail "Using cached download: $output_path"
      echo "$output_path"
      return 0
    else
      log_detail "Cached file checksum mismatch, re-downloading"
      rm -f "$output_path"
    fi
  fi

  # Download
  if ! download_file "$url" "$output_path"; then
    return 1
  fi

  # Verify
  if ! verify_checksum "$output_path" "$expected_checksum"; then
    rm -f "$output_path"
    return 1
  fi

  echo "$output_path"
}

# Extract archive to destination
# Usage: extract_archive "archive_path" "dest_dir" ["strip_components"]
extract_archive() {
  local archive="$1"
  local dest="$2"
  local strip="${3:-0}"

  mkdir -p "$dest"

  case "$archive" in
    *.tar.gz|*.tgz)
      tar -xzf "$archive" -C "$dest" --strip-components="$strip"
      ;;
    *.tar.xz)
      tar -xJf "$archive" -C "$dest" --strip-components="$strip"
      ;;
    *.tar.bz2)
      tar -xjf "$archive" -C "$dest" --strip-components="$strip"
      ;;
    *.zip)
      unzip -q -o "$archive" -d "$dest"
      ;;
    *)
      log_error "Unknown archive format: $archive"
      return 1
      ;;
  esac
}

# Install a binary to ~/.local/bin
# Usage: install_binary "source_path" "binary_name"
install_binary() {
  local source="$1"
  local name="$2"
  local dest="${HOME}/.local/bin/${name}"

  mkdir -p "${HOME}/.local/bin"

  cp "$source" "$dest"
  chmod +x "$dest"

  log_detail "Installed: $dest"
}

# Download, verify, extract, and install a GitHub release binary
# Usage: install_github_binary "owner/repo" "tool_name" "archive_template" "checksum_file" "binary_path_in_archive"
# archive_template: e.g., "helix-{VERSION}-{ARCH}-linux.tar.xz" where {VERSION} and {ARCH} are replaced
install_github_binary() {
  local repo="$1"
  local tool="$2"
  local archive_template="$3"
  local checksum_file="$4"
  local binary_in_archive="$5"
  local installed_name="${6:-$tool}"

  # Check if already installed and up to date
  if command -v "$installed_name" &>/dev/null; then
    local installed_version latest_version
    installed_version=$(get_installed_version "$installed_name" 2>/dev/null)

    # Get version to install
    latest_version=$(get_install_version "$repo" "$tool")
    if [[ -z "$latest_version" ]]; then
      log_error "Could not determine version for $tool"
      return 1
    fi

    if [[ -n "$installed_version" ]] && version_gte "$installed_version" "$latest_version"; then
      log_ok "$tool" "$installed_version" "skipped"
      return 0
    fi
  fi

  state_set_current_tool "$tool"
  log_installing "$tool"

  # Get version
  local version
  version=$(get_install_version "$repo" "$tool")
  if [[ -z "$version" ]]; then
    log_error "Could not determine latest version for $tool"
    state_record_tool_failed "$tool" "version lookup failed"
    return 1
  fi

  # Build archive filename from template
  local archive_name
  archive_name="${archive_template//\{VERSION\}/$version}"
  archive_name="${archive_name//\{ARCH\}/$RICE_ARCH}"
  archive_name="${archive_name//\{ARCH_ALT\}/$RICE_ARCH_ALT}"
  archive_name="${archive_name//\{ARCH_GO\}/$RICE_ARCH_GO}"

  # Get checksum
  local checksum
  checksum=$(get_upstream_checksum "$repo" "$version" "$checksum_file" "$archive_name")
  if [[ -z "$checksum" ]]; then
    log_error "Could not get checksum for $tool"
    log_error "Upstream must publish checksums for security"
    state_record_tool_failed "$tool" "checksum unavailable"
    return 1
  fi

  # Construct download URL
  local url="https://github.com/${repo}/releases/download/v${version}/${archive_name}"

  # Download and verify
  local archive_path
  archive_path=$(download_binary "$url" "$checksum" "$archive_name")
  if [[ -z "$archive_path" ]]; then
    # Try without 'v' prefix
    url="https://github.com/${repo}/releases/download/${version}/${archive_name}"
    archive_path=$(download_binary "$url" "$checksum" "$archive_name")
    if [[ -z "$archive_path" ]]; then
      state_record_tool_failed "$tool" "download failed"
      return 1
    fi
  fi

  # Extract
  local extract_dir
  extract_dir=$(mktemp -d)
  if ! extract_archive "$archive_path" "$extract_dir"; then
    rm -rf "$extract_dir"
    state_record_tool_failed "$tool" "extraction failed"
    return 1
  fi

  # Find and install binary
  local binary_path
  # Handle {VERSION} in binary path
  local binary_pattern="${binary_in_archive//\{VERSION\}/$version}"

  # Find the binary (could be at root or in subdirectory)
  binary_path=$(find "$extract_dir" -name "$(basename "$binary_pattern")" -type f 2>/dev/null | head -1)

  if [[ -z "$binary_path" || ! -f "$binary_path" ]]; then
    # Try direct path
    binary_path="${extract_dir}/${binary_pattern}"
  fi

  if [[ ! -f "$binary_path" ]]; then
    log_error "Binary not found in archive: $binary_pattern"
    log_detail "Archive contents:"
    find "$extract_dir" -type f | head -10 | while read -r f; do log_detail "  $f"; done
    rm -rf "$extract_dir"
    state_record_tool_failed "$tool" "binary not found in archive"
    return 1
  fi

  install_binary "$binary_path" "$installed_name"
  rm -rf "$extract_dir"

  log_ok "$tool" "$version"
  state_record_tool "$tool" "$version" "binary"
  state_clear_current_tool

  return 0
}

# Run an upstream installer script
# Usage: run_upstream_installer "url" ["installer_args"...]
run_upstream_installer() {
  local url="$1"
  shift
  local args=("$@")

  # Enforce HTTPS
  if [[ "$url" == http://* ]]; then
    log_error "Security error: HTTP URLs are not allowed"
    log_error "Installer URL must use HTTPS: $url"
    return 1
  fi

  log_detail "Running upstream installer: $url"

  local installer
  installer=$(mktemp)

  if ! curl -fsSL "$url" -o "$installer" 2>/dev/null; then
    log_error "Failed to download installer from: $url"
    rm -f "$installer"
    return 1
  fi

  chmod +x "$installer"

  # Run with provided args
  if [[ ${#args[@]} -gt 0 ]]; then
    bash "$installer" "${args[@]}"
  else
    bash "$installer"
  fi

  local result=$?
  rm -f "$installer"
  return $result
}
