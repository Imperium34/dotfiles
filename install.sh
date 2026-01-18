#!/bin/bash

# Stop script on error (so you don't end up with a half-broken system)
set -e

echo ":: INITIALIZING INSTALL SCRIPT ::"

# --- 1. INTERNET CHECK ---
echo ":: Checking Internet Connection..."
if ! ping -c 1 8.8.8.8 &>/dev/null; then
  echo "!! ERROR: No Internet Connection. Connect via nmtui first."
  exit 1
fi
echo "   -> Internet is OK."

# --- 2. PREPARATION (Paru & Base) ---
echo ":: Installing Base Tools (Paru, Git)..."
# Since you are on CachyOS, paru is in the repos.
sudo pacman -S --needed --noconfirm base-devel git paru stow

# --- 3. PACKAGE LISTS ---

# COMMON PACKAGES (Safe for Laptop & Desktop)
common_pkgs=(
  "7zip" "accountsservice" "noto-fonts-cjk" "adw-gtk-theme" "alacritty"
  "alsa-firmware" "alsa-utils" "aria2" "awesome-terminal-fonts" "bash-completion"
  "bemenu" "bemenu-wayland" "bind" "bluetui" "bluez" "bluez-hid2hci"
  "bluez-libs" "bluez-utils" "btop" "btrfs-progs" "brightnessctl" "capitaine-cursors"
  "cava" "cliphist" "cpupower" "cryptsetup" "ddcutil" "device-mapper" "diffutils"
  "dmidecode" "dnsmasq" "dosfstools" "duf" "e2fsprogs" "efibootmgr" "efitools"
  "egl-wayland" "espeak-ng" "ethtool" "exfatprogs" "fastfetch" "ffmpegthumbnailer"
  "file-roller" "fish" "flite" "fsarchiver" "github-cli" "glances" "gpicview"
  "gst-libav" "gst-plugin-pipewire" "gst-plugin-va"
  "gst-plugins-bad" "gst-plugins-ugly" "gum" "gvfs" "gvfs-mtp" "gvfs-smb" "hdparm"
  "hypridle" "hyprland" "hyprlock" "inetutils" "iptables-nft" "kvantum" "less"
  "lib32-mesa" "lib32-zlib-ng-compat" "libdvdcss" "libgsf" "libopenraw"
  "libwnck3" "linux-cachyos" "linux-cachyos-headers"
  "linux-cachyos-lts" "linux-cachyos-lts-headers" "logrotate"
  "lsb-release" "lsscsi" "man-db" "man-pages" "meld" "mesa" "mesa-utils" "mpc"
  "mpd" "mpd-mpris" "mpv" "mtools" "neovim" "networkmanager" "networkmanager-dmenu"
  "networkmanager-openvpn" "nfs-utils" "nilfs-utils" "noto-color-emoji-fontconfig"
  "noto-fonts" "noto-fonts-cjk" "noto-fonts-emoji" "nss-mdns" "ntfs-3g" "ntp"
  "nvtop" "nwg-displays" "nwg-look" "opendesktop-fonts" "openssh" "pacman-contrib"
  "pamixer" "pavucontrol" "perl" "pipewire-alsa"
  "pipewire-pulse" "pkgfile" "plocate" "hyprpolkitagent" "poppler-glib" "pv"
  "python" "qbittorrent" "qt5ct" "qt6ct" "qt5-wayland" "qt6-wayland"
  "rebuild-detector" "reflector" "ripgrep" "rmpc" "rsync" "rtkit" "sg3_utils"
  "slurp" "smartmontools" "sof-firmware" "sudo" "swaybg" "swaync"
  "sysfsutils" "texinfo" "thunar" "thunar-archive-plugin" "thunar-volman" "tmux"
  "ttf-bitstream-vera" "ttf-dejavu" "ttf-liberation" "ttf-opensans" "tumbler"
  "ufw" "unrar" "unzip" "upower" "usb_modeswitch" "usbutils" "uwsm" "waybar"
  "wget" "which" "wireless-regdb" "wireplumber" "wl-clipboard" "wlogout" "wob"
  "wofi" "wpa_supplicant" "wtype" "xdg-desktop-portal-hyprland"
  "xdg-desktop-portal-gtk" "xdg-user-dirs" "xdg-utils" "xf86-input-libinput"
  "xfsprogs" "xl2tpd" "xorg-xdpyinfo" "xorg-xrandr" "xorg-xwayland" "yazi" "zip"
  "zlib-ng-compat"
)

# AUR PACKAGES (Paru Only)
aur_pkgs=(
  "wallust" "waypaper-git"
  "windscribe-v2-bin" "grimblast-git" "ttf-ibmplex-mono-nerd"
  "ttf-meslo-nerd" "zen-browser-bin"
)

# --- 4. HARDWARE DETECTION ---
echo ":: Detecting Hardware..."

# GPU Detection logic
if lspci | grep -i "NVIDIA" >/dev/null; then
  echo "   -> Nvidia GPU detected. Adding Desktop drivers..."
  # Desktop Specifics
  common_pkgs+=("nvidia-open-dkms" "nvidia-utils" "lib32-nvidia-utils" "nvidia-settings")

elif lspci | grep -i "Intel" >/dev/null && ! lspci | grep -i "NVIDIA" >/dev/null; then
  echo "   -> Intel GPU detected. Adding Laptop drivers..."
  # Laptop Specifics (Meteor Lake / Ultra 5)
  # TLP included for battery life
  common_pkgs+=("intel-ucode" "vulkan-intel" "intel-media-driver" "thermald" "libva-intel-driver" "tlp" "tlp-rdw")
fi

# --- 5. INSTALLATION ---
echo ":: Installing Repository Packages..."
# --needed skips already installed packages
sudo pacman -S --needed --noconfirm "${common_pkgs[@]}"

echo ":: Installing AUR Packages..."
paru -S --needed --noconfirm "${aur_pkgs[@]}"

# --- 6. CONFIGURING SERVICES ---
echo ":: Enabling Services..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# Enable TLP only if we installed it (Laptop check)
if [[ " ${common_pkgs[*]} " =~ "tlp" ]]; then
  echo "   -> Enabling Laptop Battery Savers (TLP & Thermald)..."
  sudo systemctl enable --now tlp
  sudo systemctl enable --now thermald
fi

# --- 7. DOTFILES (STOW) ---
echo ":: Stowing Dotfiles..."
# List of folders in your dotfiles repo to link
dirs=(
  "hypr" "waybar" "neovim" "alacritty" "fish" "wofi" "mako" "wallust" "yazi"
)

# Backup Function to prevent stow crashes
backup_if_exists() {
  if [ -f "$HOME/.config/$1" ] || [ -d "$HOME/.config/$1" ]; then
    echo "   -> Backing up existing config for $1..."
    mv "$HOME/.config/$1" "$HOME/.config/$1.bak"
  fi
}

for dir in "${dirs[@]}"; do
  if [ -d "$dir" ]; then
    # Check specific common conflicts before stowing
    if [ "$dir" == "fish" ]; then
      if [ -f "$HOME/.config/fish/config.fish" ]; then
        mv "$HOME/.config/fish/config.fish" "$HOME/.config/fish/config.fish.bak"
      fi
    fi

    echo "   -> Stowing $dir"
    # --adopt forces stow to overwrite if file exists (use with caution, or use the backup logic above)
    stow -d .config -t "$HOME/.config" "$dir"
  else
    echo "   -> Warning: Directory $dir not found in repo, skipping."
  fi
done

# --- 8. FINAL SETUP ---
echo ":: Final Touches..."

# Set Fish as default shell
if command -v fish >/dev/null; then
  echo "   -> Changing shell to Fish..."
  sudo chsh -s /usr/bin/fish "$USER"
fi

# Disable SDDM if it snuck in (We use Hyprlock/Console start)
if systemctl is-active --quiet sddm; then
  echo "   -> Disabling SDDM (Using Hyprlock)..."
  sudo systemctl disable --now sddm
fi

echo ":: INSTALL COMPLETE! Rebooting in 5 seconds..."
sleep 5
reboot
