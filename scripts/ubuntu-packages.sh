# Ubuntu installer

#Variables
PACKAGES=('curl' 'vim' 'tmux' 'zsh' 'python3.8')

# Functions
update_packages() {
    echo "Let's update your Deb packages..."
    sudo apt update -y && sudo apt upgrade -y
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt update -y
    sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget
    echo "Packages updated!"
}

install_packages() {
    echo "Installing deb packages..."

    for PACKAGE in "${PACKAGES[@]}"; do
        echo "Installing $PACKAGE..."
        sudo apt-get install -y $PACKAGE
    done

    echo "Finished installing packages!"
}

# Update dep packages
update_packages

# install deb packages
install_packages

# Common install
scripts/common.sh

# Link dotfiles
scripts/link-files.sh
