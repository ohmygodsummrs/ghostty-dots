#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CONFIG="$REPO_DIR/config.ghostty"
TARGET_DIR="$HOME/.config/ghostty"
TARGET_CONFIG="$TARGET_DIR/config"

log() {
  printf '[ghostty-dots] %s\n' "$1"
}

install_homebrew() {
  log "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

setup_brew_shellenv() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_ghostty() {
  log "Ghostty not found. Installing Ghostty with Homebrew..."
  brew install --cask ghostty
}

ghostty_installed() {
  [[ -d "/Applications/Ghostty.app" ]] || [[ -d "$HOME/Applications/Ghostty.app" ]]
}

copy_config() {
  mkdir -p "$TARGET_DIR"

  if [[ -f "$TARGET_CONFIG" ]]; then
    local backup_path
    backup_path="$TARGET_CONFIG.backup.$(date +%Y%m%d%H%M%S)"
    cp "$TARGET_CONFIG" "$backup_path"
    log "Existing config backed up to $backup_path"
  fi

  cp "$SOURCE_CONFIG" "$TARGET_CONFIG"
  log "Ghostty config copied to $TARGET_CONFIG"
}

main() {
  if [[ ! -f "$SOURCE_CONFIG" ]]; then
    log "Source config not found: $SOURCE_CONFIG"
    log "Expected repo layout: $REPO_DIR/config.ghostty"
    exit 1
  fi

  if ghostty_installed; then
    log "Ghostty is already installed."
  else
    if ! command -v brew >/dev/null 2>&1; then
      install_homebrew
      setup_brew_shellenv
    fi

    if ! command -v brew >/dev/null 2>&1; then
      log "Homebrew is still unavailable after install."
      exit 1
    fi

    install_ghostty
  fi

  copy_config
  log "Done."
}

main "$@"
