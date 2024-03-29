# If you come from bash you might have to change your $PATH.  [16:27]
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/ozeron/.oh-my-zsh"
export ZSH_CACHE_DIR="$ZSH/cache"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="ys"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"
DISABLE_AUTO_UPDATE="false"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git gitfast git-flow fasd rails bundler macos rake ruby)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias gb="git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) |%(authorname) | (%(color:green)%(committerdate:relative)%(color:reset))| %(contents:subject) ' | column -t -s '|'"
alias gsweep='git branch --merged master | command grep -vE "^(\*|\s*develop\s*|\s*master\s*$)" | command xargs -n 1 git branch -d'

alias k="kubectl"

# ENVIRONMENT CONFIG

export EDITOR=vim
export GMAIL_EMAIL='ozeron@me.com'
export GMAIL_PASSWORD='zN7jxrsFNN$fD7kpyaJz'

# terminal colorising
export TERM=xterm-color
export CLICOLOR=1
# export LSCOLORS=fxfxcxdxbxegedabagacad
# PS1='\[\e[0;33m\]\u\[\e[0m\]@\[\e[0;32m\]\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[0m\]\$ '



# Sprinboard retail
export SR_DIR="$HOME/code/sr"
export PATH="$SR_DIR/misc/dev-tools/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
alias sagamore=sr
#export SR_MODULES="sr;landlord;eci"
export SR_MODULES="sr;landlord;eci"
# Springboard Android studio setup
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Serverless tool
export PATH="$HOME/.serverless/bin:$PATH"




# Install ASDF
. $HOME/.asdf/asdf.sh


# add yarn global to source
export PATH="$(yarn global bin):$PATH"
# add to export postgresql in PATH
export PATH="/usr/local/opt/postgresql@9.6/bin:$PATH"
export PATH="/usr/local/opt/mongodb-community@4.2/bin:$PATH"


if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval `ssh-agent -s`
  ssh-add
fi

# ITERM2 integration
source ~/.iterm2_shell_integration.zsh

# Added by serverless binary installer
export PATH="$HOME/.serverless/bin:$PATH"

# tabtab source for packages
# uninstall by removing these lines
[[ -f ~/.config/tabtab/__tabtab.zsh ]] && . ~/.config/tabtab/__tabtab.zsh || true

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /Users/ozeron/code/pdfapi/serverless/chrome/node_modules/tabtab/.completions/serverless.zsh ]] && . /Users/ozeron/code/pdfapi/serverless/chrome/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /Users/ozeron/code/pdfapi/serverless/chrome/node_modules/tabtab/.completions/sls.zsh ]] && . /Users/ozeron/code/pdfapi/serverless/chrome/node_modules/tabtab/.completions/sls.zsh



# Source [/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc] in your profile to enable shell command completion for gcloud.
source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc
# ==> Source [/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc] in your profile to add the Google Cloud SDK command line tools to your $PATH.
source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc


# add direnv
eval "$(direnv hook zsh)"

# add ssh
#ssh-add -K
ssh-add --apple-use-keychain

