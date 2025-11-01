#!/bin/bash
# ------------------------------------------------------------------
#          Imperium's dotfiles Installation & Setup Script
#
# This script installs all the packages needed for my rice.
# ------------------------------------------------------------------

# Update system first
echo "Updating system..."
sudo pacman -Syu --noconfirm

# --- Pacman Packages ---
echo "Installing Pacman packages..."

# List of core packages
CORE_PACKAGES=(
    git
    stow
    tlp
    jq
    python-colorsys
    ffmpegthumbnailer
    tumbler
    libwebp-pixbuf-loader
)

# List of UI/Hyprland packages
UI_PACKAGES=(
    hyprland
    hypridle
    hyprlock
    waybar
    wofi
    wlogout
    waypaper
    mako
    grim
    slurp
    thunar
    lxappearance
    papirus-icon-theme
    networkmanager-dmenu
)

# List of fonts
FONTS=(
    ttf-jetbrains-mono-nerd
    ttf-font-awesome
    noto-fonts-emoji
)

# List of applications
APPS=(
    firefox
    alacritty
    cava
    openrgb
    gpicview
)

# Install all packages from the lists
sudo pacman -S --needed --noconfirm ${CORE_PACKAGES[@]} ${UI_PACKAGES[@]} ${FONTS[@]} ${APPS[@]}

# --- AUR Packages ---
echo "Installing AUR packages..."

# Install base-devel (needed to build packages)
sudo pacman -S --needed base-devel

# Install 'yay' (an AUR helper)
if ! command -v yay &> /dev/null; then
    echo "yay not found. Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
else
    echo "yay is already installed."
fi

# List of AUR packages
AUR_PACKAGES=(
    wallust
)

# Install AUR packages using yay
echo "Installing AUR packages with yay..."
yay -S --needed --noconfirm ${AUR_PACKAGES[@]}

echo "---------------------------------------------------------"
echo "  All packages installed!"
echo "  Are you sure you want all of your config files to be"
echo "  deleted and my configs to be stowed in their place?"
echo "---------------------------------------------------------"
