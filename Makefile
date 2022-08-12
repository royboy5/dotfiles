.PHONY: macosx ansible-macos brew brew-update run-all 
.PHONY: arch arch-update run-all

arch: arch-update ansible-arch run-all

arch-update:
	sudo pacman -Syuu --noconfirm

ansible-arch:
	sudo pacman -S ansible --noconfirm

macosx: brew brew-upgrade ansible-macosx run-all

ansible-macosx:
		- brew install ansible

brew:
		- /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew-upgrade:
		- brew update
		-	brew upgrade
	
run-all:
		ansible-playbook ansible/install.yml --tags all -vK

