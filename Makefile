.PHONY: ansible-macos brew brew-update run-all 
.PHONY: macosx 

macosx: brew brew-upgrade ansible-macosx run-all

ansible-macosx:
		- brew install ansible

brew:
		- /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew-upgrade:
		- brew update
		-	brew upgrade
	
run-all:
		ansible-playbook ansible/install.yml --tags all -K

