# Exit immediately
set -e 

# Get the latest package list from pacman ignore archtiecture specific packages
pacman -Qqen | grep -v amdvlk | grep -v amd-ucode | grep -v base | grep -v linux | grep -v linux-firmware > package-list.txt
