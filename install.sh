#!/bin/bash

set -e

echo ":: INITIALIZING INSTALL SCRIPT ::"

# --- ERROR TRAP ---
LAST_STEP="startup"
on_error() {
  echo
  echo "!! SCRIPT FAILED during: $LAST_STEP"
  echo "!! Exit code: $?"
  echo "!! Diagnostic state:"
  echo "     sddm active:   $(systemctl is-active sddm 2>/dev/null || echo 'not found/inactive')"
  echo "     fish shell:    $(command -v fish >/dev/null && echo 'installed' || echo 'missing')"
  echo "     config.fish:   $([ -f "$HOME/.config/fish/config.fish" ] && echo 'exists' || echo 'missing')"
  echo "     uwsm autostart injected: $(grep -q 'uwsm start' "$HOME/.config/fish/config.fish" 2>/dev/null && echo 'yes' || echo 'no')"
  echo
  echo "!! Nothing further was changed. Re-run the script after fixing the issue above; steps are safe to repeat."
}
trap on_error ERR

# --- 1. INTERNET CHECK ---
LAST_STEP="internet check"
echo ":: Checking Internet Connection..."
if ! ping -c 1 8.8.8.8 &>/dev/null; then
  echo "!! ERROR: No Internet Connection. Connect via nmtui first."
  exit 1
fi
echo "   -> Internet is OK."

# --- 2. FULL SYSTEM UPDATE (must happen before installing anything) ---
LAST_STEP="full system update"
echo ":: Updating full system (required before installing new packages)..."
sudo pacman -Syu --noconfirm

# --- 3. PREPARATION (Paru & Base) ---
LAST_STEP="installing base tools"
echo ":: Installing Base Tools (Paru, Git)..."
sudo pacman -S --needed --noconfirm base-devel git paru stow

# --- 4. PACKAGE LISTS (read from repo files) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mapfile -t common_pkgs < <(grep -v '^\s*#' "$SCRIPT_DIR/pkglist_native.txt" | grep -v '^\s*$')
mapfile -t aur_pkgs < <(grep -v '^\s*#' "$SCRIPT_DIR/pkglist_aur.txt" | grep -v '^\s*$')

# --- 5. HARDWARE DETECTION ---
LAST_STEP="hardware detection"
echo ":: Detecting Hardware..."

if lspci | grep -i "NVIDIA" >/dev/null; then
  echo "   -> Nvidia GPU detected. Treating as Desktop..."
  common_pkgs+=("nvidia-open-dkms" "nvidia-utils" "lib32-nvidia-utils" "nvidia-settings" "openrgb")

elif lspci | grep -iE "VGA|3D|Display" | grep -i "Intel" >/dev/null && ! lspci | grep -i "NVIDIA" >/dev/null; then
  echo "   -> Intel GPU detected. Treating as Laptop..."
  common_pkgs+=("intel-ucode" "vulkan-intel" "intel-media-driver" "thermald" "libva-intel-driver" "tlp" "tlp-rdw" "tlp-pd" "fprintd")
fi

# --- 6. INSTALLATION ---
LAST_STEP="installing repository packages"
echo ":: Installing Repository Packages..."
sudo pacman -S --needed --noconfirm "${common_pkgs[@]}"

LAST_STEP="installing AUR packages"
echo ":: Installing AUR Packages..."
paru -S --needed --noconfirm "${aur_pkgs[@]}"

# --- 7. CONFIGURING SERVICES ---
LAST_STEP="enabling services"
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

# --- 8. STOWING DOTFILES ---
LAST_STEP="stowing dotfiles"
echo ":: Stowing Dotfiles..."
dirs=(
  "alacritty" "btop" "cava" "fastfetch" "fish" "gtk-3.0" "gtk-4.0" "hypr"
  "nvim" "quickshell" "Thunar" "wallust" "yazi"
)

for dir in "${dirs[@]}"; do
  if [ -d "$dir" ]; then
    if [ "$dir" == "fish" ] && [ -f "$HOME/.config/fish/config.fish" ] && [ ! -L "$HOME/.config/fish/config.fish" ]; then
      echo "   -> Backing up existing non-symlinked config.fish..."
      mv "$HOME/.config/fish/config.fish" "$HOME/.config/fish/config.fish.bak"
    fi

    echo "   -> Stowing $dir"
    stow -R -d .config -t "$HOME/.config" "$dir"
  else
    echo "   -> Warning: Directory $dir not found in repo, skipping."
  fi
done

# --- 9. SHELL SETUP ---
LAST_STEP="setting default shell to fish"
echo ":: Final Touches..."

if command -v fish >/dev/null; then
  if ! grep -q "/usr/bin/fish" /etc/shells; then
    echo "   -> Adding /usr/bin/fish to /etc/shells..."
    echo "/usr/bin/fish" | sudo tee -a /etc/shells
  fi
  echo "   -> Changing default shell to Fish..."
  sudo chsh -s /usr/bin/fish "$USER"
fi

# --- 10. UWSM AUTOSTART INJECTION  ---
LAST_STEP="injecting UWSM autostart into config.fish"
FISH_CONFIG="$HOME/.config/fish/config.fish"

mkdir -p "$(dirname "$FISH_CONFIG")"
touch "$FISH_CONFIG"

if ! grep -q "uwsm start" "$FISH_CONFIG" 2>/dev/null; then
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

LAST_STEP="verifying autostart injection before touching sddm"
if ! grep -q "uwsm start" "$FISH_CONFIG" 2>/dev/null; then
  echo "!! ERROR: UWSM autostart injection failed verification."
  echo "!! Refusing to disable SDDM -- you would be left with no way to log in."
  echo "!! Fix config.fish manually, or re-run this script, before disabling SDDM yourself."
  exit 1
fi
echo "   -> UWSM autostart verified present in config.fish."

# --- 11. DISABLE SDDM (only reached if autostart is confirmed working) ---
LAST_STEP="disabling sddm"
if systemctl is-active --quiet sddm; then
  echo "   -> UWSM autostart confirmed. Disabling SDDM (using UWSM from TTY)..."
  sudo systemctl disable --now sddm
else
  echo "   -> SDDM not active, nothing to disable."
fi

trap - ERR
echo ":: INSTALL COMPLETE! Rebooting in 5 seconds..."
sleep 5
reboot
