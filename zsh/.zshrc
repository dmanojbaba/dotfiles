export ZSH_DISABLE_COMPFIX="true"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git-noalias docker kubectl)

source $ZSH/oh-my-zsh.sh

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias python=python3
alias pip=pip3

alias dk=docker
alias dkc=docker-compose
alias g=git
alias k=kubectl
alias kns=kubens
alias kx=kubectx
alias tf=terraform
alias tfsw=tfswitch

# export EDITOR=vi
# export HOMEBREW_CASK_OPTS="--appdir=~/Applications"

cert() {
    openssl x509 -text -noout -in "$1"
}

encode() {
    echo "$1" | base64
    echo
}

decode() {
    echo "$1" | base64 --decode
    echo
}

if [ -f ~/dotfiles/_local/.zshrc_local ]; then
    source ~/dotfiles/_local/.zshrc_local
fi
