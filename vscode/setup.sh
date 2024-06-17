#! /usr/bin/env sh

DIR=$(dirname "$0")
cd "$DIR"

. ../common/functions.sh

extnlist=(
chrmarti.regex
eamodio.gitlens
esbenp.prettier-vscode
formulahendry.code-runner
foxundermoon.shell-format
github.vscode-github-actions
golang.go
hashicorp.terraform
kamikillerto.vscode-colorize
mechatroner.rainbow-csv
ms-azuretools.vscode-docker
ms-kubernetes-tools.vscode-kubernetes-tools
ms-python.python
ms-vscode-remote.remote-containers
ms-vscode-remote.remote-ssh
ms-vscode-remote.remote-ssh-edit
ms-vscode.remote-explorer
PKief.material-icon-theme
redhat.ansible
redhat.java
redhat.vscode-commons
redhat.vscode-xml
redhat.vscode-yaml
ria.elastic
Splunk.splunk
streetsidesoftware.code-spell-checker
VisualStudioExptTeam.vscodeintellicode
)

info "Setting Visual Studio Code..."

for extn in ${extnlist[@]}; do
	code --install-extension $extn
done

success "Finished setting up Visual Studio Code."