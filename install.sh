#!/bin/bash

# 1. The Common Core (Your Pacman List)
# These install on BOTH Laptop and Desktop
common_pkgs=(
  "7zip" "accountsservice" "noto-fonts-cjk" "adw-gtk-theme" "alacritty"
  "alsa-firmware" "alsa-utils" "aria2" "awesome-terminal-fonts" "bash-completion"
  "base-devel" "bemenu" "bemenu-wayland" "bind" "bluetui" "bluez" "bluez-hid2hci"
  "bluez-libs" "bluez-utils" "btop" "btrfs-progs" "brightnessctl" "capitaine-cursors"
  "cava" "cliphist" "cpupower" "cryptsetup" "ddcutil" "device-mapper" "diffutils"
  "dmidecode" "dnsmasq" "dosfstools" "duf" "e2fsprogs" "efibootmgr" "efitools"
  "egl-wayland" "espeak-ng" "ethtool" "exfatprogs" "fastfetch" "ffmpegthumbnailer"
  "file-roller" "fish" "flite" "fsarchiver" "git" "github-cli" "glances" "gpicview"
  "grub" "grub-hook" "gst-libav" "gst-plugin-pipewire" "gst-plugin-va"
  "gst-plugins-bad" "gst-plugins-ugly" "gum" "gvfs" "gvfs-mtp" "gvfs-smb" "hdparm"
  "hypridle" "hyprland" "hyprlock" "inetutils" "iptables-nft" "kvantum" "less"
  "lib32-mesa" "lib32-zlib-ng-compat" "libdvdcss" "libgsf" "libopenraw"
  "libreoffice-still" "libwnck3" "linux-cachyos" "linux-cachyos-headers"
  "linux-cachyos-lts" "linux-cachyos-lts-headers" "linux-headers" "logrotate"
  "lsb-release" "lsscsi" "man-db" "man-pages" "meld" "mesa" "mesa-utils" "mpc"
  "mpd" "mpd-mpris" "mpv" "mtools" "neovim" "networkmanager" "networkmanager-dmenu"
  "networkmanager-openvpn" "nfs-utils" "nilfs-utils" "noto-color-emoji-fontconfig"
  "noto-fonts" "noto-fonts-cjk" "noto-fonts-emoji" "nss-mdns" "ntfs-3g" "ntp"
  "nvtop" "nwg-displays" "nwg-look" "opendesktop-fonts" "openssh" "pacman-contrib"
  "pamixer" "paru" "pavucontrol" "perl" "piper-tts-bin" "pipewire-alsa"
  "pipewire-pulse" "pkgfile" "plocate" "hyprpolkitagent" "poppler-glib" "pv"
  "python" "qbittorrent" "qt5ct" "qt6ct" "qt5-wayland" "qt6-wayland"
  "rebuild-detector" "reflector" "ripgrep" "rmpc" "rsync" "rtkit" "sg3_utils"
  "slurp" "smartmontools" "sof-firmware" "stow" "sudo" "swaybg" "swaync"
  "sysfsutils" "texinfo" "thunar" "thunar-archive-plugin" "thunar-volman" "tmux"
  "ttf-bitstream-vera" "ttf-dejavu" "ttf-liberation" "ttf-opensans" "tumbler"
  "ufw" "unrar" "unzip" "upower" "usb_modeswitch" "usbutils" "uwsm" "waybar"
  "wget" "which" "wireless-regdb" "wireplumber" "wl-clipboard" "wlogout" "wob"
  "wofi" "wpa_supplicant" "wtype" "xdg-desktop-portal-hyprland"
  "xdg-desktop-portal-gtk" "xdg-user-dirs" "xdg-utils" "xf86-input-libinput"
  "xfsprogs" "xl2tpd" "xorg-xdpyinfo" "xorg-xrandr" "xorg-xwayland" "yazi" "zip"
  "zlib-ng-compat"
)

# 2. The AUR List (Your Paru List)
aur_pkgs=(
  "mecab-git" "mecab-ipadic" "pahole-git" "wallust" "waypaper-git"
  "windscribe-v2-bin" "grimblast-git" "ttf-ibmplex-mono-nerd"
  "ttf-meslo-nerd" "zen-browser-bin"
)

# --- HARDWARE DETECTION & DRIVER INJECTION ---
echo ":: Detecting Hardware..."

# GPU Detection
if lspci | grep -i "NVIDIA" >/dev/null; then
  echo "   -> Nvidia GPU detected. Adding Desktop drivers..."
  # Desktop Specifics
  common_pkgs+=("nvidia-open-dkms" "nvidia-utils" "lib32-nvidia-utils" "nvidia-settings")

elif lspci | grep -i "Intel" >/dev/null && ! lspci | grep -i "NVIDIA" >/dev/null; then
  echo "   -> Intel GPU detected. Adding Laptop drivers..."
  # Laptop Specifics (Meteor Lake / Ultra 5)
  # Added TLP here as requested
  common_pkgs+=("intel-ucode" "vulkan-intel" "intel-media-driver" "thermald" "libva-intel-driver" "tlp" "tlp-rdw")
fi

# --- INSTALLATION ---
echo ":: Installing Repository Packages..."
sudo pacman -S --needed --noconfirm "${common_pkgs[@]}"

echo ":: Installing AUR Packages..."
paru -S --needed --noconfirm "${aur_pkgs[@]}"

# --- SERVICE ACTIVATION (Crucial Step) ---
echo ":: Enabling Services..."
# Network & Bluetooth
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# Laptop Specific Services
if [[ " ${common_pkgs[*]} " =~ "tlp" ]]; then
  echo "   -> Enabling TLP for battery life..."
  sudo systemctl enable --now tlp
  sudo systemctl enable --now thermald
fi

# --- DOTFILES STOWING ---
# Assumes this script is running from inside your ~/dotfiles folder
echo ":: Linking Dotfiles..."
dirs=(
  "hypr"
  "waybar"
  "nvim"
  "alacritty"
  "fish"
  "wofi"
  "mako"
  "wallust"
  "gtk-3.0"
  "gtk-4.0"
  "waypaper"
  "yazi"
  "fastfetch"
  "cava"
  "btop"
  "Thunar"
  "wlogout"
)

for dir in "${dirs[@]}"; do
  if [ -d "$dir" ]; then
    echo "   -> Stowing $dir"
    stow "$dir"
  else
    echo "   -> Warning: Directory $dir not found, skipping."
  fi
done

# --- SHELL CONFIGURATION ---
echo ":: Changing default shell to Fish..."
# Check if fish is actually installed first
if command -v fish >/dev/null; then
  # chsh usually asks for password, this attempts to do it for the current user
  sudo chsh -s /usr/bin/fish "$USER"
fi

echo ":: SYSTEM SETUP COMPLETE! Reboot recommended."
