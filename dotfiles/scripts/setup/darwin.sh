#!/usr/bin/env bash

set -euo pipefail
IFS=$'\t\n'

fancy_echo() {
  local fmt="$1"
  shift
  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    fancy_echo "Homebrew already installed. Skipping ..."
    return
  fi

  fancy_echo "Installing Homebrew ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

brew_install_or_upgrade() {
  local formula="$1"
  if brew list --formula | grep -Fqx "$formula"; then
    if brew outdated --quiet "$formula" >/dev/null 2>&1; then
      fancy_echo "Upgrading %s ..." "$formula"
      brew upgrade "$formula"
    else
      fancy_echo "Already using the latest %s. Skipping ..." "$formula"
    fi
  else
    fancy_echo "Installing %s ..." "$formula"
    brew install "$formula"
  fi
}

brew_install_cask_if_missing() {
  local cask="$1"
  if brew list --cask | grep -Fqx "$cask"; then
    if brew outdated --cask --quiet "$cask" >/dev/null 2>&1; then
      fancy_echo "Upgrading %s ..." "$cask"
      brew upgrade --cask "$cask"
    else
      fancy_echo "Already using the latest %s. Skipping ..." "$cask"
    fi
  else
    fancy_echo "Installing %s ..." "$cask"
    brew install --cask "$cask"
  fi
}

ensure_prezto() {
  if [ -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
    fancy_echo "Prezto already installed. Skipping ..."
    return
  fi

  fancy_echo "Cloning Prezto ..."
  git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
}

ensure_env_file() {
  local env_file="$HOME/.env"
  if [ ! -f "$env_file" ]; then
    fancy_echo "Creating %s ..." "$env_file"
    touch "$env_file"
  fi
}

ensure_homebrew

fancy_echo "Updating Homebrew formulas ..."
brew update

# Terminal apps
brew_install_cask_if_missing ghostty
brew_install_cask_if_missing raycast
brew_install_cask_if_missing font-jetbrains-mono-nerd-font
brew_install_cask_if_missing ukrainian-unicode-layout

# Shell and editors
brew_install_or_upgrade zsh
brew_install_or_upgrade git
brew_install_or_upgrade vim
brew_install_or_upgrade ctags
brew_install_or_upgrade direnv

# Search and navigation
brew_install_or_upgrade ripgrep
brew_install_or_upgrade fd
brew_install_or_upgrade zoxide
brew_install_or_upgrade fzf
brew_install_or_upgrade bat
brew_install_or_upgrade eza
brew_install_or_upgrade atuin
brew_install_or_upgrade tldr
brew_install_or_upgrade jq

# Git and terminal workflow
brew_install_or_upgrade git-delta
brew_install_or_upgrade lazygit
brew_install_or_upgrade tmux
brew_install_or_upgrade zellij

# Runtime and toolchain
brew_install_or_upgrade mise
brew_install_or_upgrade gnupg
brew_install_or_upgrade readline
brew_install_or_upgrade openssl

# Power tools
brew_install_or_upgrade btop
brew_install_or_upgrade yazi
brew_install_or_upgrade dust
brew_install_or_upgrade sd
brew_install_or_upgrade glow
brew_install_or_upgrade hyperfine

ensure_prezto
ensure_env_file

fancy_echo "Bootstrap complete. Run ./dotfiles/scripts/makesymlinks.sh next."
