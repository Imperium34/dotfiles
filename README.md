# Imperium's Automated Hyprland Rice

This is my personal Hyprland setup running on CachyOS. The entire theme is automatically generated from the current wallpaper using `wallust` and syncs with all my RGB devices via `openrgb`.

[Example 1](https://imgur.com/YzzPaq2)

[Example 2](https://imgur.com/Sn8ZvP7)

## 🚀 Key Features

* **Automated Theming:** The entire system theme (Waybar, Alacritty, Wofi, Mako, etc.) is generated on the fly from the wallpaper using `wallust`.
* **RGB Sync:** All `openrgb` devices are automatically set to the most vibrant color from the wallpaper palette.
* **Laptop & Desktop Ready:** Includes `TLP` for laptop battery life and a Battery module in `Waybar`

## 📦 Software & Dependencies

This setup is built on CachyOS (Arch-based) and relies on the following key components.

* **Window Manager:** `hyprland`
* **Bar:** `waybar`
* **Wallpaper** `waypaper` (with swaybg backend)
* **Launcher:** `wofi`
* **Terminal:** `alacritty`
* **Theming:** `wallust`
* **File Manager:** `thunar`
* **Notifications:** `mako`
* **RGB:** `openrgb`

### Installation

All required packages can be installed by running the `install.sh` script included in this repository. after installing the packages the script will delete all of the old config files for the software like waybar and link them to their counterparts in the dotfiles folder. to use wallust all you have to do is change your wallpaper with waypaper
