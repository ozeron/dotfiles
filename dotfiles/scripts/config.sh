#!/bin/bash -
###############################################################################
# setup.sh
# This script creates everything needed to get started on a new laptop
###############################################################################
# Unoffical Bash "strict mode"
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\t\n' # Stricter IFS settings
ORIGINAL_IFS=$IFS

cd $HOME

DOTFILES_DIR=$HOME/code/dotfiles
DOTFILE_SCRIPTS_DIR=$DOTFILES_DIR/dotfiles/scripts
unamestr=$(uname)

# Run the OS-specific setup scripts
if [[ "$unamestr" == 'Darwin' ]]; then
    bash "$DOTFILE_SCRIPTS_DIR/setup/darwin.sh"
elif [[ "$unamestr" == 'Linux' ]]; then
    bash "$DOTFILE_SCRIPTS_DIR/setup/linux.sh"
fi

###############################################################################
# Create symlinks to custom config now that all the software is installed
###############################################################################
$DOTFILE_SCRIPTS_DIR/makesymlinks.sh

if command -v mise >/dev/null 2>&1; then
    echo "Installing runtime versions from .tool-versions via mise..."
    mise install
else
    echo "mise is not installed or not in PATH; skipping runtime install."
fi
