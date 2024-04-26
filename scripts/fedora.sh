# Fedora Installer

# Update system
sudo dnf update -y && sudo dnf upgrade -y

# Install ansible
sudo dnf install ansible -y

# Run ansible
ansible-playbook ansible/install.yml --tags "wsl,fedora" -vK
