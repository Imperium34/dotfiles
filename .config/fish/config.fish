source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

if status is-login
   if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
      exec uwsm start hyprland.desktop
   end
end

function fish_greeting
   if test "$TERM_PROGRAM" != "vscode" -a -f ~/.cache/wallust/sequences
       fastfetch
       cat ~/.cache/wallust/sequences
   end
end


# Generated for envman. Do not edit.
test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish
