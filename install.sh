#!/usr/bin/env bash
set -e

PKG_LIST_PATH="${HOME}/.config/zsh/pkglist_$(cat /etc/hostname).txt"

install_prerequisites() {
    echo "Updating and installing git and zsh"
    sudo pacman -Syu git zsh
}

install_packages() {
    echo "Updating and installing packages"
    sudo pacman -S - < "$PKG_LIST_PATH" 
}

configure_github() {
    read -p "Enter your Git username: " GIT_NAME
    read -p "Enter your Git email: " GIT_EMAIL
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"

    SSH_FILE="$HOME/.ssh/id_ed25519"
    if [ ! -f "$SSH_FILE" ]; then
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_FILE" -N ""
    fi

    echo "Copy the following SSH key and add it to your GitHub account:"
    cat "$SSH_FILE.pub"
    read -n1 -rsp $'Press any key to continue once you have added the SSH key to GitHub...\n'
}

setup_dotfiles() {
    mkdir -p "$HOME/Workplace"
    cd "$HOME/Workplace"
    git clone --bare git@github.com:sourabh-pisal/dotfiles.git "$HOME/Workplace/dotfiles"
    alias dotfiles="/usr/bin/git --git-dir=$HOME/Workplace/dotfiles --work-tree=$HOME"
    /usr/bin/git --git-dir="$HOME/Workplace/dotfiles" --work-tree="$HOME" switch -f mainline
    /usr/bin/git --git-dir="$HOME/Workplace/dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
}

install_tmux_tpm() {
  TPM_DIR="$HOME/.tmux/plugins/tpm"
  
  if [ ! -d "$TPM_DIR" ]; then
      echo "Cloning TPM repository..."
      git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  else
      echo "TPM repository already exists. Skipping clone."
  fi
}

install_omzsh() {
  OMZ_DIR="$HOME/.oh-my-zsh"

  if [ ! -d "$OMZ_DIR" ]; then
      echo "Installing Oh My Zsh..."
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
      echo "Oh My Zsh is already installed. Skipping installation."
  fi
}

set_gpg_pass() {
  gpg --full-generate-key
  GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep sec | tail -n1 | awk '{print $2}' | cut -d'/' -f2)
  pass init "$GPG_KEY_ID"
}

set_default_shell() {
  chsh -s $(which zsh)
}

set_wallpaper() {
  mkdir ~/Pictures
  cp /usr/share/backgrounds/sway/Sway_Wallpaper_Blue_1920x1080.png ~/Pictures/wallpaper.png
}

set_groups() {
  sudo groupadd davfs2
  sudo usermod -aG davfs2 $USER
  sudo usermod -aG network $USER
  newgrp network
  newgrp davfs2
}

set_power_button_to_suspend() {
    local file="/etc/systemd/logind.conf"

    sudo sed -i \
        -e '/^HandlePowerKey=/d' \
        -e '/^HandlePowerKeyLongPress=/d' \
        "$file"

    sudo sh -c "
        echo 'HandlePowerKey=suspend' >> $file
        echo 'HandlePowerKeyLongPress=poweroff' >> $file
    "
}


main() {
    install_prerequisites
    configure_github
    install_tmux_tpm
    install_omzsh
    setup_dotfiles
    install_packages
    set_gpg_pass
    set_wallpaper
    set_default_shell
    set_groups
    set_power_button_to_suspend

    echo "Setup completed successfully!"
}

main
