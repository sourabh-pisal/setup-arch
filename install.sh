#!/usr/bin/env bash
set -e

PKG_LIST_PATH="${HOME}/.config/zsh/pkglist_$(cat /etc/hostname).txt"

install_prerequisites() {
    echo "Install necessary packages"
    sudo pacman -Syu git 
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
    git config --global pull.rebase true

    SSH_FILE="$HOME/.ssh/id_ed25519"
    if [ ! -f "$SSH_FILE" ]; then
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_FILE" -N ""
    fi

    echo "Copy the following SSH key and add it to your GitHub account:"
    cat "$SSH_FILE.pub"

    while true; do
        read -p "Press 'y' to continue once you have added the SSH key to GitHub: " confirm
        case "$confirm" in
            [yY]) break ;;
            *) echo "Please press 'y' to continue." ;;
        esac
    done
}

setup_dotfiles() {
    mkdir -p "$HOME/workspace"
    cd "$HOME/workspace"
    git clone --bare git@github.com:sourabh-pisal/dotfiles.git "$HOME/workspace/dotfiles"
    alias dotfiles="/usr/bin/git --git-dir=$HOME/workspace/dotfiles --work-tree=$HOME"
    /usr/bin/git --git-dir="$HOME/workspace/dotfiles" --work-tree="$HOME" switch -f mainline
    /usr/bin/git --git-dir="$HOME/workspace/dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
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

set_wallpaper() {
  if ! command -v sway >/dev/null 2>&1; then
    echo "Sway is not installed. Skipping wallpaper setup."
    return 0
  fi

  mkdir ~/Pictures
  cp /usr/share/backgrounds/sway/Sway_Wallpaper_Blue_1920x1080.png ~/Pictures/wallpaper.png
}

set_groups() {
  local user="${SUDO_USER:-$USER}"

  ensure_group() {
    local grp="$1"
    if ! getent group "$grp" >/dev/null; then
      echo "Creating group: $grp"
      sudo groupadd "$grp"
    else
      echo "Group exists: $grp"
    fi
  }

  ensure_user_in_group() {
    local grp="$1"
    if id -nG "$user" | grep -qw "$grp"; then
      echo "User already in group: $grp"
    else
      echo "Adding $user to group: $grp"
      sudo usermod -aG "$grp" "$user"
      NEED_RELOGIN=1
    fi
  }

  NEED_RELOGIN=0

  # create groups if missing
  ensure_group davfs2
  ensure_group docker
  ensure_group network

  # add user if missing
  ensure_user_in_group davfs2
  ensure_user_in_group docker
  ensure_user_in_group network
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
    setup_dotfiles
    install_packages
    set_wallpaper
    set_groups
    set_power_button_to_suspend

    echo "Setup completed successfully!"
}

main
