#!/bin/sh

sudo apt-get update && sudo apt-get install -y libonig-dev

# cat << EOF >> ~/.bashrc
# export SSH_AUTH_SOCK=~/.ssh/ssh-agent.\$HOSTNAME.sock
# EOF

## Install Ansible Development Tools
cp .devcontainer/.ansible.cfg ~/.ansible.cfg
pip install --upgrade ansible-dev-tools

## Install k0sctl
go install github.com/k0sproject/k0sctl@latest

## Install dotfiles
chezmoi init --apply https://github.com/sicruse/chezmoi.git

#sudo curl -sSLf https://get.k0s.sh | sh 
# && \
#     mv k0sctl /usr/local/bin/ && \
#     chmod +x /usr/local/bin/k0sctl
