#! /bin/bash
sudo convert ~/.cache/awesome/wallpaper /boot/efi/EFI/refind/themes/rEFInd-sunset/background.png
sudo cp ~/.cache/awesome/wallpaper /usr/share/sddm/themes/sugar-candy/Backgrounds/wpgtk.png
sudo cp  ~/.cache/awesome/templates/start-page.css /usr/share/start-page/styles.css
sudo cp  ~/.cache/awesome/templates/sddm-sugar-candy.conf /usr/share/sddm/themes/sugar-candy/theme.conf

telegram-palette-gen --wal
pywalfox update
pgrep -u $USER -x Discord > /dev/null && discocss
spicetify update -q
