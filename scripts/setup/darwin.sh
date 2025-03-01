#!/usr/bin/env bash

# Unoffical Bash "strict mode"
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
#ORIGINAL_IFS=$IFS
IFS=$'\t\n' # Stricter IFS settings

fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

brew_install_or_upgrade() {
  if brew_is_installed "$1"; then
    if brew_is_upgradable "$1"; then
      fancy_echo "Upgrading %s ..." "$1"
      brew upgrade "$@"
    else
      fancy_echo "Already using the latest version of %s. Skipping ..." "$1"
    fi
  else
    fancy_echo "Installing %s ..." "$1"
    brew install "$@"
  fi
}

brew_is_installed() {
  local name="$(brew_expand_alias "$1")"

  brew list -1 | grep -Fqx "$name"
}

brew_is_upgradable() {
  local name="$(brew_expand_alias "$1")"

  ! brew outdated --quiet "$name" >/dev/null
}

brew_tap() {
  brew tap "$1" 2> /dev/null
}

brew_expand_alias() {
  brew info "$1" 2>/dev/null | head -1 | awk '{gsub(/:/, ""); print $1}'
}

brew_launchctl_restart() {
  local name="$(brew_expand_alias "$1")"
  local domain="homebrew.mxcl.$name"
  local plist="$domain.plist"

  fancy_echo "Restarting %s ..." "$1"
  mkdir -p "$HOME/Library/LaunchAgents"
  ln -sfv "/usr/local/opt/$name/$plist" "$HOME/Library/LaunchAgents"

  if launchctl list | grep -Fq "$domain"; then
    launchctl unload "$HOME/Library/LaunchAgents/$plist" >/dev/null
  fi
  launchctl load "$HOME/Library/LaunchAgents/$plist" >/dev/null
}

gem_install_or_update() {
  if gem list "$1" --installed > /dev/null; then
    fancy_echo "Updating %s ..." "$1"
    gem update "$@"
  else
    fancy_echo "Installing %s ..." "$1"
    gem install "$@"
  fi
}

if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew ..."
    curl -fsS \
      'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby

    export PATH="/usr/local/bin:$PATH"
else
  fancy_echo "Homebrew already installed. Skipping ..."
fi

create_env_file() {
  local env_file="$HOME/.env"
  
  if [ ! -f "$env_file" ]; then
    fancy_echo "Creating .env file in HOME directory ..."
    touch "$env_file"
  else
    fancy_echo ".env file already exists in HOME directory. Skipping ..."
  fi
}


fancy_echo "Updating Homebrew formulas ..."
brew update

brew_install_or_upgrade 'zsh'
brew_install_or_upgrade 'git'
# brew_install_or_upgrade 'the_silver_searcher'
brew_install_or_upgrade 'vim'
brew_install_or_upgrade 'ctags'
brew_install_or_upgrade 'tldr'
brew_install_or_upgrade 'asdf'
brew_install_or_upgrade 'powerlevel10k'
brew_install_or_upgrade 'direnv'
# brew_install_or_upgrade 'tmux' --with-utf8proc
# $HOME/dotfiles/script/setup/tmux.sh
# brew_install_or_upgrade 'imagemagick'
# brew_install_or_upgrade 'qt'
# brew_install_or_upgrade 'shellcheck'
# brew_install_or_upgrade 'telnet'

# For Postgres
# brew_install_or_upgrade 'postgresql@9.6'
# For Ruby
brew_install_or_upgrade readline

# For various languages that use OpenSSL
brew_install_or_upgrade 'openssl'
brew unlink openssl && brew link openssl --force

# brew_install_or_upgrade 'libyaml'

# Warning this is failed
# gem update --system

# gem_install_or_update 'bundler'

# fancy_echo "Configuring Bundler ..."
#   number_of_cores=$(sysctl -n hw.ncpu)
#   bundle config --global jobs $((number_of_cores - 1))

# Exuberant Ctags
brew_install_or_upgrade ctags


brew install --cask ukrainian-unicode-layout
brew_install_or_upgrade gum

# Visualization library
# brew_install_or_upgrade graphviz --with-app
# brew link graphviz

# Gimp for image editing
# brew_tap homebrew/cask
# brew cask install gimp

# Inkscape for vector graphics
# brew cask install xquartz
# brew cask install inkscape

# For image metadata manipulation
# brew_install_or_upgrade exiftool

# Install command-line JSON processor
# brew_install_or_upgrade jq

# Install pandoc
# brew_install_or_upgrade pandoc

# WxWidgets for Erlang
# brew_install_or_upgrade wxmac --with-static --with-stl --universal

# Install pianobar for music
# brew_install_or_upgrade pianobar

# For JSON pretty printing in the quicklook window
# brew cask install quicklook-json

# QCacheGrind for valgrind analysis
# brew_install_or_upgrade qcachegrind --with-graphviz

# For watching for file change events
# brew_install_or_upgrade entr

# Install GNU readlink
# brew_install_or_upgrade coreutils

# Install GNU sed
# brew_install_or_upgrade gnu-sed

# autoexpect
# brew_install_or_upgrade expect
brew install awscli

# For adb
# brew_tap caskroom/cask
# brew cask install android-sdk
# brew cask install android-platform-tools

# Mosh for high latency remote servers
# brew_install_or_upgrade mobile-shell

# For wrapping shells that don't use readline
# brew_install_or_upgrade rlwrap

# For password management
# brew_install_or_upgrade pass

# Elm for packages that require it
# brew_install_or_upgrade elm

# For network troubleshooting
# brew_install_or_upgrade mtr

# OSX alternative to `ps auxf` for process tree views
# brew_install_or_upgrade pstree

# Required by asdf-nodejs
brew_install_or_upgrade gnupg

# Images in the terminal
# brew_tap eddieantonio/eddieantonio
# brew_install_or_upgrade imgcat

# Install tools for server testing and administration
# brew_install_or_upgrade ansible

# For VMs and Vagrant
# brew cask install virtualbox
# brew cask install vagrant
# brew cask install vagrant-manager # OSX toolbar for vagrant

# For MySQL migrations
# brew_install_or_upgrade percona-toolkit

# Install iperf3 for network performance tests
# brew_install_or_upgrade iperf3

# For web server performance
# brew_install_or_upgrade siege

# I should probably create an asdf plugin for RabbitMQ
# brew_install_or_upgrade rabbitmq

# For IRC
# brew_install_or_upgrade weechat

# Install other software using custom install scripts
# run_install_scripts

create_env_file

###############################################################################
# Configure OSX
###############################################################################

# $HOME/dotfiles/scripts/setup/macos-defaults

# Insall open Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
