#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_GHOSTTY_DIR="$HOME/.config/ghostty"
TARGET_GHOSTTY_CONFIG="$TARGET_GHOSTTY_DIR/config"
TARGET_GHOSTTY_THEME_DIR="$TARGET_GHOSTTY_DIR/ghostty"
TARGET_POSH_DIR="$HOME/.config/ohmyposh"
TARGET_POSH_CONFIG="$TARGET_POSH_DIR/config.omp.json"
THEME="${1:-}"

log() {
  printf '[ghostty-dots] %s\n' "$1"
}

set_theme_paths() {
  case "$THEME" in
    1|gruvbox-paper|gruvbox)
      THEME="gruvbox-paper"
      SOURCE_GHOSTTY_CONFIG="$REPO_DIR/config.ghostty"
      SOURCE_GHOSTTY_THEME_DIR="$REPO_DIR/ghostty"
      SOURCE_POSH_CONFIG="$REPO_DIR/ohmyposh/gruvbox-paper.omp.json"
      ;;
    2|tokyo-night|tokyonight)
      THEME="tokyo-night"
      SOURCE_GHOSTTY_CONFIG="$REPO_DIR/config-tokyo-night.ghostty"
      SOURCE_GHOSTTY_THEME_DIR="$REPO_DIR/ghostty"
      SOURCE_POSH_CONFIG="$REPO_DIR/ohmyposh/tokyo-night.omp.json"
      ;;
    *)
      log "Unknown theme: $THEME"
      log "Use one of: 1, 2, gruvbox-paper, tokyo-night"
      exit 1
      ;;
  esac
}

prompt_theme_choice() {
  printf 'Choose Ghostty theme:\n'
  printf '1) gruvbox-paper\n'
  printf '2) tokyo-night\n'
  printf '> '
  read -r THEME
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

install_oh_my_posh() {
  log "oh-my-posh not found. Installing oh-my-posh with Homebrew..."
  brew install jandedobbeleer/oh-my-posh/oh-my-posh
}

ghostty_installed() {
  [[ -d "/Applications/Ghostty.app" ]] || [[ -d "$HOME/Applications/Ghostty.app" ]]
}

backup_file() {
  local target_path="$1"

  if [[ -f "$target_path" ]]; then
    local backup_path
    backup_path="$target_path.backup.$(date +%Y%m%d%H%M%S)"
    cp "$target_path" "$backup_path"
    log "Existing config backed up to $backup_path"
  fi
}

copy_configs() {
  mkdir -p "$TARGET_GHOSTTY_DIR" "$TARGET_POSH_DIR"

  backup_file "$TARGET_GHOSTTY_CONFIG"
  cp "$SOURCE_GHOSTTY_CONFIG" "$TARGET_GHOSTTY_CONFIG"
  rm -rf "$TARGET_GHOSTTY_THEME_DIR"
  cp -R "$SOURCE_GHOSTTY_THEME_DIR" "$TARGET_GHOSTTY_THEME_DIR"
  log "Ghostty theme '$THEME' copied to $TARGET_GHOSTTY_CONFIG"

  backup_file "$TARGET_POSH_CONFIG"
  cp "$SOURCE_POSH_CONFIG" "$TARGET_POSH_CONFIG"
  log "oh-my-posh theme '$THEME' copied to $TARGET_POSH_CONFIG"
}

ensure_zshrc_has_oh_my_posh() {
  local zshrc_path="$HOME/.zshrc"

  if [[ -f "$zshrc_path" ]] && grep -q 'oh-my-posh init zsh' "$zshrc_path"; then
    log ".zshrc already initializes oh-my-posh."
    return
  fi

  cat >>"$zshrc_path" <<'EOF'

export OMP_CONFIG="$HOME/.config/ohmyposh/config.omp.json"

if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config "$OMP_CONFIG")"
fi
EOF
  log "Added oh-my-posh init block to $zshrc_path"
}

main() {
  if [[ -z "$THEME" ]]; then
    prompt_theme_choice
  fi

  set_theme_paths

  if [[ ! -f "$SOURCE_GHOSTTY_CONFIG" ]]; then
    log "Source Ghostty config not found: $SOURCE_GHOSTTY_CONFIG"
    exit 1
  fi

  if [[ ! -d "$SOURCE_GHOSTTY_THEME_DIR" ]]; then
    log "Source Ghostty theme dir not found: $SOURCE_GHOSTTY_THEME_DIR"
    exit 1
  fi

  if [[ ! -f "$SOURCE_POSH_CONFIG" ]]; then
    log "Source oh-my-posh config not found: $SOURCE_POSH_CONFIG"
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

  if ! command -v oh-my-posh >/dev/null 2>&1; then
    if ! command -v brew >/dev/null 2>&1; then
      install_homebrew
      setup_brew_shellenv
    fi

    if ! command -v brew >/dev/null 2>&1; then
      log "Homebrew is still unavailable after install."
      exit 1
    fi

    install_oh_my_posh
  else
    log "oh-my-posh is already installed."
  fi

  copy_configs
  ensure_zshrc_has_oh_my_posh
  log "Done."
}

main "$@"
