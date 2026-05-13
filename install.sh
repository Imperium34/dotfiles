#!/bin/bash

# Stop script on error
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
sudo pacman -S --needed --noconfirm base-devel git paru stow

# --- 3. PACKAGE LISTS ---

sys_pkgs=(
  "7zip" "accountsservice" "alsa-firmware" "alsa-utils" "bind" "bluez"
  "bluez-hid2hci" "bluez-libs" "bluez-utils" "btrfs-assistant" "btrfs-progs"
  "cpupower" "cryptsetup" "device-mapper" "diffutils" "dmidecode" "dnsmasq"
  "dosfstools" "e2fsprogs" "efibootmgr" "efitools" "ethtool" "exfatprogs"
  "fsarchiver" "gvfs" "gvfs-mtp" "gvfs-smb" "hdparm" "inetutils" "iptables-nft"
  "linux-cachyos" "linux-cachyos-headers" "linux-cachyos-lts"
  "linux-cachyos-lts-headers" "logrotate" "lsb-release" "lsscsi" "man-db"
  "man-pages" "networkmanager" "networkmanager-openvpn" "nfs-utils"
  "nilfs-utils" "ntfs-3g" "ntp" "openssh" "pacman-contrib" "plocate"
  "pv" "rsync" "rtkit" "sg3_utils" "smartmontools" "snapper" "sof-firmware"
  "sudo" "sysfsutils" "ufw" "usb_modeswitch" "usbutils" "wget" "which"
  "wireless-regdb" "xfsprogs" "xl2tpd" "zip"
)

wayland_core=(
  "hyprland" "hypridle" "hyprlock" "hyprpolkitagent" "uwsm" "waybar" "wlogout"
  "wofi" "swaybg" "swaync" "swayosd" "xdg-desktop-portal-hyprland"
  "xdg-desktop-portal-gtk" "xdg-user-dirs" "xdg-utils" "qt5-wayland"
  "qt6-wayland" "nwg-displays" "nwg-look" "egl-wayland" "xorg-xwayland"
  "wl-clipboard" "wtype" "slurp" "grim" "cliphist" "bemenu" "bemenu-wayland"
)

media_fonts_theme=(
  "adw-gtk-theme" "awesome-terminal-fonts" "capitaine-cursors" "cava"
  "ffmpegthumbnailer" "gst-libav" "gst-plugin-pipewire" "gst-plugin-va"
  "gst-plugins-bad" "gst-plugins-ugly" "kvantum" "noto-color-emoji-fontconfig"
  "noto-fonts" "noto-fonts-cjk" "noto-fonts-emoji" "opendesktop-fonts"
  "pamixer" "pavucontrol" "pipewire-alsa" "pipewire-pulse" "playerctl"
  "qt5ct" "qt6ct" "ttf-bitstream-vera" "ttf-dejavu" "ttf-liberation"
  "ttf-opensans" "tumbler" "wireplumber"
)

dev_apps=(
  "alacritty" "aria2" "bluetui" "btop" "brightnessctl" "ddcutil" "docker"
  "duf" "espeak-ng" "fastfetch" "file-roller" "fish" "flite" "foliate"
  "github-cli" "glances" "gpicview" "gum" "less" "meld" "mgba-qt" "mpc"
  "mpd" "mpd-mpris" "mpv" "mtools" "neovim" "networkmanager-dmenu" "nodejs"
  "npm" "nvtop" "perl" "pkgfile" "poppler-glib" "prismlauncher" "python"
  "qbittorrent" "rebuild-detector" "reflector" "ripgrep" "rmpc" "steam"
  "syncthing" "tailscale" "texinfo" "thunar" "thunar-archive-plugin"
  "thunar-volman" "tmux" "umu-launcher" "unrar" "unzip" "uv" "yazi"
)

# Combine into common array
common_pkgs=("${sys_pkgs[@]}" "${wayland_core[@]}" "${media_fonts_theme[@]}" "${dev_apps[@]}")

# AUR PACKAGES (Paru Only)
aur_pkgs=(
  "bibata-cursor-theme" "grimblast-git" "otf-departure-mono" "ttf-ibmplex-mono-nerd"
  "ttf-meslo-nerd" "visual-studio-code-bin" "wallust" "waypaper-git"
  "windscribe-v2-bin" "youtube-music" "zen-browser-bin" "zoom"
)

# --- 4. HARDWARE DETECTION ---
echo ":: Detecting Hardware..."

if lspci | grep -i "NVIDIA" >/dev/null; then
  echo "   -> Nvidia GPU detected. Adding Desktop drivers & heavy tools..."
  common_pkgs+=("nvidia-open-dkms" "nvidia-utils" "lib32-nvidia-utils" "nvidia-settings" "ollama" "openrgb")
  aur_pkgs+=("piper-tts-bin")

elif lspci | grep -iE "VGA|3D|Display" | grep -i "Intel" >/dev/null && ! lspci | grep -i "NVIDIA" >/dev/null; then
  echo "   -> Intel GPU detected. Adding Laptop drivers..."
  common_pkgs+=("intel-ucode" "vulkan-intel" "intel-media-driver" "thermald" "libva-intel-driver" "tlp" "tlp-rdw")
fi

# --- 5. INSTALLATION ---
echo ":: Installing Repository Packages..."
sudo pacman -S --needed --noconfirm "${common_pkgs[@]}"

echo ":: Installing AUR Packages..."
paru -S --needed --noconfirm "${aur_pkgs[@]}"

# --- 6. CONFIGURING SERVICES ---
echo ":: Enabling Services..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

if [[ " ${common_pkgs[*]} " =~ "ollama" ]]; then
  echo "   -> Enabling Ollama Daemon (Desktop AI)..."
  sudo systemctl enable --now ollama
fi

if [[ " ${common_pkgs[*]} " =~ "tlp" ]]; then
  echo "   -> Enabling Laptop Battery Savers (TLP & Thermald)..."
  sudo systemctl enable --now tlp
  sudo systemctl enable --now thermald
fi

# --- 7. DOTFILES (STOW) ---
echo ":: Stowing Dotfiles..."
dirs=(
  "alacritty" "btop" "cava" "fastfetch" "fish" "gtk-3.0" "gtk-4.0" "hypr"
  "nvim" "swaync" "swayosd" "Thunar" "wallust" "waybar" "waypaper" "wlogout"
  "wofi" "yazi"
)

for dir in "${dirs[@]}"; do
  if [ -d "$dir" ]; then
    if [ "$dir" == "fish" ] && [ -f "$HOME/.config/fish/config.fish" ]; then
      echo "   -> Backing up existing config.fish..."
      mv "$HOME/.config/fish/config.fish" "$HOME/.config/fish/config.fish.bak"
    fi

    echo "   -> Stowing $dir"
    stow -d .config -t "$HOME/.config" "$dir"
  else
    echo "   -> Warning: Directory $dir not found in repo, skipping."
  fi
done

# --- 8. FINAL SETUP & UWSM INTEGRATION ---
echo ":: Final Touches..."

# Robust Shell Change
if command -v fish >/dev/null; then
  if ! grep -q "/usr/bin/fish" /etc/shells; then
    echo "   -> Adding /usr/bin/fish to /etc/shells..."
    echo "/usr/bin/fish" | sudo tee -a /etc/shells
  fi
  echo "   -> Changing default shell to Fish..."
  sudo chsh -s /usr/bin/fish "$USER"
fi

# Disable SDDM if active
if systemctl is-active --quiet sddm; then
  echo "   -> Disabling SDDM (Using UWSM from TTY)..."
  sudo systemctl disable --now sddm
fi

# Inject UWSM autostart into Fish config
FISH_CONFIG="$HOME/.config/fish/config.fish"
if [ -f "$FISH_CONFIG" ] && ! grep -q "uwsm start" "$FISH_CONFIG" 2>/dev/null; then
  echo "   -> Injecting UWSM Hyprland autostart into config.fish..."
  cat <<'EOF' >>"$FISH_CONFIG"

# UWSM Autostart for Hyprland (TTY1 only)
if status is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
        exec uwsm start hyprland.desktop
    end
end
EOF
fi

echo ":: INSTALL COMPLETE! Rebooting in 5 seconds..."
sleep 5
reboot
