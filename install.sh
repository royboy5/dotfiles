#!/usr/bin/env bash

#########################################
# Bash script to configure a new system #
#########################################

echo "Welcome!!! Let's begin your system setup!"

while true; do
    echo -n "What is your OS? [A]rch / [F]edora / [U]buntu: "
    read OS_INPUT

    case $OS_INPUT in
        [aA])
            OS="Arch"
            break
            ;;
        [fF])
            OS="Fedora"
            break
            ;;
        [uU])
            OS="Ubuntu"
            break
            ;;
        *)
            echo "Bad entry.  Please try again!"
            ;;
    esac
done

echo "You have selected $OS"
echo "Let's update your packages..."

while true; do
    case $OS in
        Arch)
            sudo pacman -Syu
            break
            ;;
        Fedora)
            sudo dnf update && dnf upgrade
            break
            ;;
        Ubuntu)
            sudo apt update -y && sudo apt upgrade -y
            break
            ;;
    esac
done

echo "Packages updated!"