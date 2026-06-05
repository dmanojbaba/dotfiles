# source $HOME/dotfiles/zsh/.zshrc

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias c="code ."
alias g=git
alias k=kubectl
alias kns=kubens
alias kx=kubectx
alias tf=terraform
alias tfsw=tfswitch

export EDITOR=vi
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

source $HOME/dotfiles/zsh/gwt.zsh

if [ -f ~/dotfiles/_local/.zshrc_local ]; then
    source ~/dotfiles/_local/.zshrc_local
fi
