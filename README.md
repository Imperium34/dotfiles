# Hyprland + Quickshell Dotfiles

My personal Linux desktop, running Hyprland on CachyOS with a fully custom shell built in [Quickshell](https://quickshell.outfoxxed.me/) — bar, OSD, app launcher, clipboard manager, lockscreen, and notification center are all native Quickshell/QML, not a patchwork of separate daemons. The entire color scheme is generated live from the current wallpaper via `wallust` and propagated through the shell and (on desktop) synced to RGB peripherals via `openrgb`.

## 🚀 Key Features

- **Custom Quickshell shell** — a single coordinated shell replacing the usual bar/launcher/notification-daemon/lockscreen stack:
  - **Bar** — three-pill layout with interactive modules (workspaces, media player, system monitor, clock, audio, backlight, network, bluetooth, battery, tray, notifications) — nearly every module opens its own popup rather than being a static readout
  - **OSD** — custom on-screen display for volume/brightness/
  - **Launcher** — native app launcher
  - **Clipboard manager** — Quickshell frontend over `cliphist`
  - **Notification center** — SwayNC-inspired, built natively in Quickshell (toast + history/center view)
  - **Lockscreen** — native Quickshell lock screen
  - **Wallpaper picker** — choose a wallpaper, and it's automatically piped into `wallust` to regenerate the shell's theme
  - **Fallback TUIs** — Bluetooth/network modules can drop into their TUI equivalents (`bluetui`, etc.) for anything the custom UI doesn't cover
- **Automated theming** — `wallust` generates colors from the active wallpaper and feeds them into the Quickshell theme, Hyprland, Alacritty, btop, cava, and GTK
- **Dual-machine ready** — `install.sh` detects GPU (Nvidia → desktop profile, Intel → laptop profile) and installs the right package set automatically:
  - **Desktop:** Nvidia drivers + `openrgb` for RGB sync
  - **Laptop:** Intel drivers, `tlp`/`tlp-rdw`/`tlp-pd` for battery/profile management, `fprintd` for fingerprint unlock
- **Fish shell** as default, launched into Hyprland via `uwsm`

## 📦 Software & Dependencies

- **Window Manager:** `hyprland`
- **Shell (bar/OSD/launcher/clipboard/lockscreen/notifications):** `quickshell-git`
- **Wallpaper daemon:** `awww`
- **Theming:** `wallust`
- **Terminal:** `alacritty`
- **File Manager:** `thunar` (GUI), `yazi` (TUI)
- **Shell:** `fish`
- **RGB (desktop only):** `openrgb`
- **Power management (laptop only):** `tlp`, `tlp-rdw`, `tlp-pd`

Full package lists live in [`pkglist_native.txt`](./pkglist_native.txt) and [`pkglist_aur.txt`](./pkglist_aur.txt).

## 🛠️ Installation

```bash
git clone https://github.com/aliaricode/dotfiles.git
cd dotfiles
./install.sh
```

The script will:

1. Check for an internet connection and install `paru`/`stow`/base tools
2. Install packages from `pkglist_native.txt` (pacman) and `pkglist_aur.txt` (paru)
3. Detect your GPU and install the appropriate desktop/laptop extras
4. Stow all config directories into `~/.config`
5. Set `fish` as your default shell and wire up `uwsm` autostart for Hyprland
6. Reboot

To change your theme, just pick a new wallpaper through the Quickshell wallpaper picker — `wallust` handles the rest automatically.

## 📁 Structure

```
.config/
├── hypr/           # Hyprland config (Lua-based, see hypr/lua/)
├── quickshell/      # The custom shell: bar, OSD, launcher, clipboard, lockscreen, notifications
├── wallust/         # Theme templates driven by the active wallpaper
├── fish/, alacritty/, btop/, cava/, nvim/, yazi/, Thunar/, gtk-3.0/, gtk-4.0/
```

## Notes

- `hypr/old_config/` in this repo is a legacy config kept for reference and is not stowed by `install.sh`.
- `openrgb` is only installed automatically on machines with an Nvidia GPU (treated as "desktop" by the install script's hardware detection).
