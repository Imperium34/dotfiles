#!/bin/bash

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

# --- 3. PACKAGE LISTS (read from repo files) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mapfile -t common_pkgs < <(grep -v '^\s*#' "$SCRIPT_DIR/pkglist_native.txt" | grep -v '^\s*$')
mapfile -t aur_pkgs < <(grep -v '^\s*#' "$SCRIPT_DIR/pkglist_aur.txt" | grep -v '^\s*$')

# --- 4. HARDWARE DETECTION ---
echo ":: Detecting Hardware..."

if lspci | grep -i "NVIDIA" >/dev/null; then
  echo "   -> Nvidia GPU detected. Treating as Desktop..."
  common_pkgs+=("nvidia-open-dkms" "nvidia-utils" "lib32-nvidia-utils" "nvidia-settings" "openrgb")

elif lspci | grep -iE "VGA|3D|Display" | grep -i "Intel" >/dev/null && ! lspci | grep -i "NVIDIA" >/dev/null; then
  echo "   -> Intel GPU detected. Treating as Laptop..."
  common_pkgs+=("intel-ucode" "vulkan-intel" "intel-media-driver" "thermald" "libva-intel-driver" "tlp" "tlp-rdw" "tlp-pd" "fprintd")
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

if [[ " ${common_pkgs[*]} " =~ "tlp" ]]; then
  echo "   -> Enabling Laptop Battery Savers (TLP & Thermald)..."
  sudo systemctl enable --now tlp
  sudo systemctl enable --now thermald
fi

if [[ " ${common_pkgs[*]} " =~ "fprintd" ]]; then
  echo "   -> fprintd installed. Run 'fprintd-enroll' to register a fingerprint."
fi

if [[ " ${common_pkgs[*]} " =~ "openrgb" ]]; then
  echo "   -> openrgb installed. Autostart/color sync is handled by hypr/scripts/update-rgb.sh."
else
  echo "   -> Skipping openrgb (not a Desktop/Nvidia machine). Install manually if needed."
fi

# --- 7. STOWING DOTFILES ---
echo ":: Stowing Dotfiles..."
dirs=(
  "alacritty" "btop" "cava" "fastfetch" "fish" "gtk-3.0" "gtk-4.0" "hypr"
  "nvim" "quickshell" "Thunar" "wallust" "yazi"
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

if command -v fish >/dev/null; then
  if ! grep -q "/usr/bin/fish" /etc/shells; then
    echo "   -> Adding /usr/bin/fish to /etc/shells..."
    echo "/usr/bin/fish" | sudo tee -a /etc/shells
  fi
  echo "   -> Changing default shell to Fish..."
  sudo chsh -s /usr/bin/fish "$USER"
fi

if systemctl is-active --quiet sddm; then
  echo "   -> Disabling SDDM (Using UWSM from TTY)..."
  sudo systemctl disable --now sddm
fi

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
