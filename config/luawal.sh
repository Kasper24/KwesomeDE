#! /bin/bash
sudo convert ~/.config/wpg/.current /boot/efi/EFI/refind/themes/rEFInd-sunset/background.png
sudo cp ~/.config/wpg/.current /usr/share/sddm/themes/sugar-candy/Backgrounds/wpgtk.png
sudo cp  ~/.cache/awesome/templates/start-page.css /usr/share/start-page/styles.css
sudo cp  ~/.cache/awesome/templates/sddm-sugar-candy.conf /usr/share/sddm/themes/sugar-candy/theme.conf

telegram-palette-gen --wal
pywalfox update
~/Dotfiles/packages/wal-vivaldi/generator.py
pgrep -u $USER -x Discord > /dev/null && discocss
spicetify update -q
