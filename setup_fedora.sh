#!/bin/bash

# Store the parameter
stage=$1

# Сначала займемся апдейтом
if [ -z "$stage" ] || [ "$stage" -eq 1 ]; then
  echo "Update System"
  # Remove openh264
  # Disable fedora-cisco-open264
  # From https://forum.qubes-os.org/t/guide-fix-fedora-updates-failing-in-russia-and-ukraine/35724
  sudo sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-cisco-open264.repo
  sudo dnf swap openh264 noopenh264 --allowerasing 
  # Update system
  sudo dnf update

  echo "Setup VPN before proceeding to stage 2"
fi

# Execute different code based on the stage
if [ "$stage" -eq 2 ]; then
    echo "Install Brave"
    # Install brave - https://brave.com/linux/
    sudo dnf install dnf-plugins-core
    sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo dnf install brave-browser

    echo "Setup Flatpak"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    echo "Install Flatpack Main Apps"
    flatpak install flathub org.telegram.desktop org.mozilla.Thunderbird com.getpostman.Postman
    echo "Details to configure Thunderbird: https://timeweb.cloud/docs/mail/configuring-email-clients/thunderbird" 

    echo "Install dnf Main Apps"
    sudo dnf copr enable dejan/lazygit
    sudo dnf install libreoffice vlc lazygit

    echo "Install Dev Utils"
    sudo dnf install git nvim kitty fzf ripgrep fd 
    npm install -g tree-sitter-cli
    # If get access error look into https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally

    echo "Setup Git"
    git config --global user.email "dev@ivashk.ru"
    git config --global user.name "Roman Ivashkin"
    git config --global core.editor nvim
    git config --global init.defaultbranch main
if [ "$stage" -eq 3 ]; then
    echo "Clean up"
    sudo remove firefox foot
else
    echo "Error: Invalid option. Please use 1, 2 or 3"
    exit 1
fi
