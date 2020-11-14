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
DOTFILE_SCRIPTS_DIR=$DOTFILES_DIR/scripts






# Run the OS-specific setup scripts
if [[ "$unamestr" == 'Darwin' ]]; then
    "$DOTFILE_SCRIPTS_DIR/setup/darwin.sh"
elif [[ "$unamestr" == 'Linux' ]]; then
    "$DOTFILE_SCRIPTS_DIR/setup/linux.sh"
fi

###############################################################################
# Install asdf for version management
###############################################################################
asdf_dir=$HOME/.asdf
cd $HOME

if [ ! -d $asdf_dir ]; then
    echo "Installing asdf..."
    git clone https://github.com/asdf-vm/asdf.git $asdf_dir
    echo "asdf installation complete"
else
    echo "asdf already installed"
fi

# Load ASDF binary
. $HOME/.asdf/asdf.sh


###############################################################################
# Create symlinks to custom config now that all the software is installed
###############################################################################
$DOTFILE_SCRIPTS_DIR/makesymlinks.sh




# Install all the plugins needed
asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git || true
asdf plugin-add postgres https://github.com/smashedtoatoms/asdf-postgres.git || true
asdf plugin-add python https://github.com/danhper/asdf-python.git || true
asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git || true
asdf plugin-add yarn https://github.com/twuni/asdf-yarn.git || true

# Imports Node.js release team's OpenPGP keys to main keyring
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring || true

# Install the software versions listed in the .tool-versions file in $HOME
asdf install
