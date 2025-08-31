#!/usr/bin/env bash
set -e

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo "Cannot detect Linux distribution!"
        exit 1
    fi
    echo "Detected Linux distribution: $DISTRO"
}

install_prerequisites() {
    case "$DISTRO" in
        ubuntu|debian)
            echo "Updating and installing packages on Debian/Ubuntu"
            sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
            xargs sudo apt-get -y install < debianpkglist.txt
            ;;
        
        arch)
            echo "Updating and installing packages on Arch Linux"
            sudo pacman -Syu --noconfirm
            sudo pacman -Sy --noconfirm --needed base-devel btop file fzf gcc git lazygit neovim procps-ng ripgrep tmux zsh
            ;;
        
        *)

            echo "Unsupported distribution: $DISTRO"
            exit 1
            ;;

    esac
}

configure_github() {
    read -p "Enter your Git username: " GIT_NAME
    read -p "Enter your Git email: " GIT_EMAIL
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    echo "Git global config set:"
    git config --global --list

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

set_default_shell() {
  chsh -s $(which zsh)
}

main() {
    detect_distro
    install_prerequisites
    configure_github
    setup_dotfiles
    install_tmux_tpm
    install_omzsh
    set_default_shell
    echo "Setup completed successfully!"
}

main
