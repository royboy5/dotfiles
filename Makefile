.PHONY: arch arch-update run-all
.PHONY: fedora-wsl fedora-update fedora-ansible run-all 

arch: arch-update arch-ansible run-all

arch-update:
	sudo pacman -Syuu --noconfirm

arch-ansible:
	sudo pacman -S ansible --noconfirm

fedora-wsl: fedora-update fedora-ansible run-all

fedora-update:
	sudo dnf update && sudo dnf upgrade

fedora-ansible:
	sudo dnf install ansible

# ubuntu: ubuntu-update ubuntu-install run-all

# ubuntu-update:
# 	sudo apt update -y

# ubuntu-install:
# 	sudo apt install ansible unzip -y

run-all:
	ansible-playbook ansible/install.yml --tags all -vK
