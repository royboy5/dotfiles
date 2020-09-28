#!/usr/bin/env bash

#########################################
# Bash script to configure a new system #
#########################################


echo "Welcome!!! Let's begin your system setup!"

while true; do
    # echo -n "What is your OS? [A]rch / [F]edora / [D]ebian: "
    echo -n "What is your OS? [D]ebian: "

    read OS_INPUT

    case $OS_INPUT in
        # [aA])
        #     OS="Arch"
        #     break
        #     ;;
        # [fF])
        #     OS="Fedora"
        #     break
        #     ;;
        [dD])
            OS="Debian"
            echo "You have selected $OS"
            scripts/ubuntu-packages.sh
            break
            ;;
        *)
            echo "Bad entry.  Please try again!"
            ;;
    esac
done

# TODO
# options for full install / basics / apps / etc

