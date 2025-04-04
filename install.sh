# Exit immediately
set -e 

# Update package manager
sudo pacman -Syu --noconfirm

# Install required packages 
sudo pacman -S --noconfirm git zsh

# Create workplace dir
mkdir -p $HOME/workplace

# Change dir to workplace
cd $HOME/workplace

# Clone setup-arch repository
git clone https://github.com/sourabh-pisal/setup-arch.git

# Change dir to setup-arch
cd $HOME/workplace/setup-arch

# Run setup script
./setup.sh
