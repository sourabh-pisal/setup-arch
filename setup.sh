# Exit immediately
set -e 

# cleanup old dotfiles
rm -rf $HOME/workplace/dotfiles

# Install omzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Change dir to workplace
cd $HOME/workplace

# Create alias for dotfiles
alias dotfiles="/usr/bin/git --git-dir=$HOME/workplace/dotfiles --work-tree=$HOME"

# Clone dotfiles bare repository
git clone --bare https://github.com/sourabh-pisal/dotfiles.git $HOME/workplace/dotfiles

# Change dir to dotfiles
cd $HOME/workplace/dotfiles

# Setup dotfiles
/usr/bin/git --git-dir=$HOME/workplace/dotfiles --work-tree=$HOME switch -f mainline
/usr/bin/git --git-dir=$HOME/workplace/dotfiles --work-tree=$HOME config --local status.showUntrackedFiles no

# Set zsh as default shell
chsh -s $(which zsh)
