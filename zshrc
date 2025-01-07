# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===========================
# Oh My Zsh Configuration
# ===========================

export ZSH="$HOME/.oh-my-zsh"
export ZSH_CACHE_DIR="$ZSH/cache"

# Theme Configuration
ZSH_THEME="ys"

# Plugins
plugins=(
  git
  # git-flow
  # gitfast
  # fasd
  # rails
  # bundler
  macos
  # rake
  # ruby
)

# Initialize Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# ===========================
# Environment Variables
# ===========================

# Locale Settings
export LANG="en_US.UTF-8"

# Editor Configuration
export EDITOR="vim"

# Path Modifications
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.rvm/bin:$HOME/.nodenv/shims:$HOME/.codeium/windsurf/bin:$PATH"

# Additional Paths for ASDF
export PATH="$HOME/.asdf/bin:$PATH"
export PATH="$HOME/.asdf/shims:$PATH"

# Language Managers
# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"
# eval "$(asdf init -)"  # This line is causing the issue and should be removed
# . "$HOME/.asdf/asdf.sh"

# AWS Configuration
# export AWS_PROFILE="toptal"

# Serverless and Google Cloud SDK Completions
# source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
# source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"

# Direnv
eval "$(direnv hook zsh)"

# SSH Agent Setup
if [[ -z "$SSH_AUTH_SOCK" ]]; then
  eval "$(ssh-agent -s)"
  ssh-add --apple-use-keychain
fi

# ===========================
# ASDF Configuration
# ===========================

# Add ASDF to PATH
export PATH="$HOME/.asdf/bin:$PATH"

# Source ASDF
if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
fi

# Optional: Source ASDF completions
if [ -f "$HOME/.asdf/completions/asdf.zsh" ]; then
  . "$HOME/.asdf/completions/asdf.zsh"
fi

# ===========================
# Aliases
# ===========================

alias gb='git for-each-ref --sort=committerdate refs/heads/ --format="%(HEAD) %(color:yellow)%(refname:short)%(color:reset) |%(authorname) | (%(color:green)%(committerdate:relative)%(color:reset))| %(contents:subject)" | column -t -s "|"'
alias gsweep='git branch --merged master | grep -vE "^(\*|\s*develop\s*|\s*master\s*$)" | xargs -n 1 git branch -d'
alias k="kubectl"
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# ===========================
# Functions
# ===========================

lazy_git() {
  git add .
  git commit -m "$1"
  git push
}

new_project() {
  local dry_run=0
  local project_name=""
  local show_help=0

  for arg in "$@"; do
    case $arg in
      --dry)
        dry_run=1
        ;;
      --help)
        show_help=1
        ;;
      *)
        project_name="$arg"
        ;;
    esac
  done

  if [[ $show_help -eq 1 ]]; then
    echo "This function initializes a new project directory with a unique numeric prefix."
    echo "Usage: new_project [OPTIONS] [PROJECT_NAME]"
    echo "Options:"
    echo "  --dry    Simulate the creation of a new project directory without actually creating it."
    echo "  --help   Display this detailed help message and exit."
    return 0
  fi

  # Find the highest numbered project
  last_project=$(ls | grep -E '^[0-9]{4}[_-]' | sort -r | head -n 1)

  # Extract the number from the project name and increment it
  if [[ $last_project =~ ^([0-9]+)[_-] ]]; then
    next_number=$((10#${match[1]} + 1))
    next_number=$(printf "%04d" "$next_number")
  else
    echo "No matching project found. Setting default number."
    next_number="0001"
  fi

  # Create a new project directory with the next number
  new_project_name="${next_number}-${project_name}"

  if [[ $dry_run -eq 1 ]]; then
    echo "DRY RUN: Project folder '$new_project_name' would be created."
  else
    mkdir -p "$new_project_name"
    echo "Project folder '$new_project_name' created."
  fi
}

restart_audio() {
  sudo pkill -x coreaudio
  echo "coreaudio processes terminated."
}

# ===========================
# Sourcing External Files
# ===========================

# iTerm2 Integration
if [[ -f "$HOME/.iterm2_shell_integration.zsh" ]]; then
  source "$HOME/.iterm2_shell_integration.zsh"
fi

# Tabtab Completions
[[ -f "$HOME/.config/tabtab/__tabtab.zsh" ]] && source "$HOME/.config/tabtab/__tabtab.zsh"

# Serverless Completions
for completion in "serverless" "sls"; do
  local comp_path="$HOME/code/pdfapi/serverless/chrome/node_modules/tabtab/.completions/$completion.zsh"
  [[ -f "$comp_path" ]] && source "$comp_path"
done

# Fabric Bootstrap
if [[ -f "$HOME/.config/fabric/fabric-bootstrap.inc" ]]; then
  source "$HOME/.config/fabric/fabric-bootstrap.inc"
fi

# Bun Completions and Installation
if [[ -s "$HOME/.bun/_bun" ]]; then
  source "$HOME/.bun/_bun"
fi
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Active RVM
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
  source "$HOME/.rvm/scripts/rvm"
fi

# Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# Rust Environment via ASDF
#source "$HOME/.asdf/installs/rust/1.73/env"

# ===========================
# Miscellaneous Settings
# ===========================

# Enable Command Auto-Correction
ENABLE_CORRECTION="true"

# Enable Completion Waiting Dots
COMPLETION_WAITING_DOTS="true"

# Preferred Editor for Project Files
# Uncomment and customize if needed
# export EDITOR='mvim'

# ===========================
# End of .zshrc
# ===========================

source "$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

