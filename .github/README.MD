<!-- DOTFILES BANNER -->
<p align="center">
  <img width="25%" src="https://github.com/Kasper24.png" />
</p>

<p align="center">
  <b>🎀 Kasome 🎀</b>
</p>

<p align="center">
<a href="#wrench--setup"><img width="150px" style="padding: 0 10px;" src="assets/setup.png"></a>
<a href="https://github.com/rxyhn/dotfiles/wiki"><img width="150px" style="padding: 0 10px;" src="assets/wiki.png"></a>
<a href="#ocean--gallery"><img width="150px" style="padding: 0 10px;" src="assets/gallery.png"></a>
<a href="#money_with_wings--tip-jar"><img width="150px" style="padding: 0 10px;" src="assets/tipjar.png"></a>
</p>

<br>

<table>
  <tr>
    <td></td>
     <td></td>
     <td></td>
  </tr>
  <tr>
    <td><img src="assets/1.png" </td>
    <td><img src="assets/2.png" ></td>
    <td><img src="assets/3.png" ></td>
  </tr>
  <tr>
    <td><img src="assets/4.png" </td>
    <td><img src="assets/5.png" </td>
    <td><img src="assets/6.png" </td>
  </tr>
 </table>


## Hi there! 🖤
<a href="https://awesomewm.org/"><img alt="AwesomeWM Logo" height="150" align = "left" src="https://awesomewm.org/doc/api/images/AUTOGEN_wibox_logo_logo_and_name.svg"></a>

<b>  Beautiful & Aesthetic AwesomeWM Configuration Files!  </b>

Welcome to my AwesomeWM configuration files!

This is my personal collection of configuration files.

You might be here for looking my AwesomeWM configuration files? or looking for **Linux Rice** reference?

feel free to steal anything from here but don't forget to give me **credits** :)

AwesomeWM is the most powerful and highly configurable, next generation framework window manager for X,
Although it takes time and effort to configure it, but I'm very satisfied with the result.

This is a beautiful user interface isn't it?

These dotfiles are made with love, for sure.

<!-- INFORMATION -->
## :snowflake: ‎ <samp>Information</samp> <img alt="" align="right" src="https://badges.pufler.dev/visits/rxyhn/dotfiles?style=for-the-badge&color=6791C9&logoColor=white&labelColor=0A1419"/>

<img alt="Rice Preview" align="right" width="400px" src="assets/night.png"/>

Here are some details about my setup:

- **OS:** [Arch Linux](https://archlinux.org)
- **WM:** [awesome](https://github.com/awesomeWM/awesome)
- **Terminal:** [kitty](https://github.com/alacritty/alacritty)
- **Shell:** [zsh](https://www.zsh.org/)
- **Editor:** [VSCode](https://github.com/neovim/neovim) / [vscode](https://github.com/microsoft/vscode)
- **Compositor:** [picom-dccsillag](https://github.com/dccsillag/picom/tree/implement-window-animations)
- **Music Player** [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp)

AwesomeWM Modules:
- **[bling](https://github.com/blingcorp/bling)**
   + Adds new layouts, modules, and widgets that try to primarily focus on window management
- **[layout-machi](https://github.com/xinhaoyuan/layout-machi)**
   + Manual layout for Awesome with an interactive editor

<br>
<!-- SETUP -->
## :wrench: ‎ <samp>Setup</samp>
</table>

### :computer: ‎ <samp>Install Dependencies<samp>

> First of all you should install the [git version of AwesomeWM](https://github.com/awesomeWM/awesome/).

**Arch users** can use the [awesome-git AUR package](https://aur.archlinux.org/packages/awesome-git/).
   ```sh
   paru -S awesome-git
   ```

**For other distros**, build instructions are [here](https://github.com/awesomeWM/awesome/#building-and-installation).

> Install necessary dependencies

| Dependency                              | Why/Where is it needed?                                   |
|-----------------------------------------|-----------------------------------------------------------|
| awesome-git                             | (explains itself)                                         |
| networkmanager                          | Network notifcations, applet/wibar widget                 |
| blueman                                 | Bluetooth notifcations, applet/wibar widget               |
| pactl                                   | Audio notifcations, applet/wibar widget                   |
| pipewire+pipewire-pulse/pulsaudio       | Used by pactl                                             |
| lm_sensors                              | CPU Temperature                                           |
| inotify-tools                           | Daemons that monitor filesystem events                    |
| redshift                                | Blue light toggle                                         |
| maim                                    | Screenshot widget                                         |
| ffmpeg                                  | Record widget                                             |
| xdotool                                 | Menu commands use this to input text into terminal        |
| upower                                  | Battery notifications/widgets                             |
| picom                                   | Compositor widget/notifcations                            |
| brightnessctl                           | Brightness daemon and widget                              |
| playerctl                               | Media daemon and controls                                 |
| fortune-mod                             | Fortune daemon (right now that daemon is unused)          |

**Arch Linux (and other Arch-based distributions)**

   Assuming your **AUR Helper** is [paru](https://github.com/Morganamilo/paru).

   ```sh
   paru -Sy picom-git alacritty todo-bin papirus-icon-theme acpi acpid \
   acpi_call wireless_tools jq inotify-tools polkit-gnome xdotool xclip \
   brightnessctl alsa-utils alsa-tools pulseaudio pulseaudio-alsa scrot \
   redshift mpd mpc mpdris2 ncmpcpp playerctl rofi ffmpeg bluez-utils gpick --needed
   ```

### :bookmark_tabs: ‎ <samp>Install Needed Fonts<samp>

> You will need to install a few fonts (mainly icon fonts) in order for text and icons to be rendered properly.

Necessary fonts:
   + **Iosevka**              - [here](https://github.com/be5invis/Iosevka)
   + **Icomoon**              - [here](https://www.dropbox.com/s/hrkub2yo9iapljz/icomoon.zip?dl=0)
   + **Material Icons**       - [here](https://github.com/google/material-design-icons)
   + **FiraCode Nerd Font**   - [here](https://github.com/ryanoasis/nerd-fonts)

Also you can find the required icon fonts inside the `misc/fonts` folder of this repository.

Once you download them and unpack them, place them into `~/.fonts` or `~/.local/share/fonts`

And run this command for your system to detect the newly installed fonts.

   ```sh
   fc-cache -v
   ```

### :art: ‎ <samp>Install my AwesomeWM configuration files<samp>

> Clone this repository

   ```sh
   git clone https://github.com/Kasper24/KwesomeDE --recurse-submodules
   ```

> Copy config and binaries files

   ```sh
   cp -r KwesomeDE/* ~/.config/awesome
   ```

> Finally, now you can login with AwesomeWM

   Congratulations, at this point you have installed this aesthetic dotfiles! :tada:

   Log out from your current desktop session and log in into AwesomeWM

<!-- GALLERY -->
## :ocean: ‎ <samp>Gallery</samp>

<b>These are the features included in my AwesomeWM setups!</b>

   + Minimalist `wibar` design
      - <details open>
         <summary>Preview</summary>

         *Simple, Minimalist and Modern Bar Design!*

         - App launcher
         - Web search
         - Taglist
         - Battery indicator
         - Clock
         - Layoutbox

         <div align="left">
         <img src="assets/wibar.gif" width="500px" alt="dashboard preview">
         </div>
         </details>
   + Aesthetic `Dashboard` ngl.
      - <details open>
         <summary>Preview</summary>

         *Aesthetic dashboard with neat grid layout, it's so beautiful!*

         - Time & date
         - Pfp display
         - ToDo reminder
         - Hardware stats
         - Weather widget
         - Music player
         - Notifs center

         <div align="left">
         <img src="assets/dashboard.gif" width="500px" alt="dashboard preview">
         </div>
         </details>
   + Very useful `Control Center` ikr.
      - <details open>

          *This control center has many features!*

         - Exit screen
         - Volume & brightness control
         - DnD, Blue light & Airplane mode
         - Floating layout mode
         - Theme switcher
         - Wifi, Bluetooth and Microphone toggle
         - built in screenrec and screensht widgets
         - Hardware Monitor

         <summary>Preview</summary>
         <div align="left">
         <img src="assets/control-center.gif" width="500px" alt="control center preview">
         </div>
         </details>
   + Custom mouse-friendly `ncmpcpp` UI with album art ofc.
      - <details open>
         <summary>Preview</summary>

         *This is so aesthetic isn't it?*

         <div align="left">
         <img src="assets/ncmpcpp.gif" width="500px" alt="ncmpcpp preview">
         </div>
         </details>
   + `Word Clock Lockscreen` with PAM Integration!
      - <details open>

         *A beautiful word clock is on the lockscreen!*

         <summary>Preview</summary>
         <div align="left">
         <img src="assets/lockscreen.gif" width="500px" alt="word clock lockscreen preview">
         </div>
         </details>

<!-- MISCELLANEOUS -->
## :four_leaf_clover: ‎ <samp>Miscellaneous</samp>

<details>
<summary><strong>Configure stuff</strong></summary>

> The relevant files are inside your `~/.config/awesome` directory.

+ User preferences and default applications

   In `rc.lua` there is a *Default Applications* section where user preferences and default applications are defined.
   You should change those to your liking.

Note: For the weather widgets to work, you will also need to create an account on [openweathermap](https://openweathermap.org), get your key, look for your city ID, and set `openweathermap_key` and `openweathermap_city_id` accordingly.

</details>

<details>
<summary><strong>Keybinds</strong></summary>

I use <kbd>super</kbd> AKA Windows key as my main modifier.
also with <kbd>alt, shift, and ctrl</kbd>

**Keyboard**

| Keybind                                 | Action                                                    |
|-----------------------------------------|-----------------------------------------------------------|
| <kbd>super + enter</kbd>                | Spawn terminal                                            |
| <kbd>super + grave</kbd>                | Spawn music client                                        |
| <kbd>super + d</kbd>                    | Spawn application launcher                                |
| <kbd>super + shift + w</kbd>            | Spawn web browser                                         |
| <kbd>super + shift + x</kbd>            | Spawn color picker                                        |
| <kbd>super + shift + f</kbd>            | Spawn file manager                                        |
| <kbd>super + shift + d</kbd>            | Toggle central panel                                      |
| <kbd>super + shift + t</kbd>            | Toggle system tray                                        |
| <kbd>super + q</kbd>                    | Close client                                              |
| <kbd>super + x</kbd>                    | Exit screen                                               |
| <kbd>super + ctrl + l</kbd>             | Lock screen                                               |
| <kbd>super + [1-0]</kbd>                | View tag AKA change workspace (for you i3/bsp folks)      |
| <kbd>super + shift + [1-0]</kbd>        | Move focused client to tag                                |
| <kbd>super + space</kbd>                | Select next layout                                        |
| <kbd>super + s</kbd>                    | Set tiling layout                                         |
| <kbd>super + shift + s</kbd>            | Set floating layout                                       |
| <kbd>super + c</kbd>                    | Center floating client                                    |
| <kbd>super + [arrow keys]</kbd>         | Change focus by direction                                 |
| <kbd>super + f</kbd>                    | Toggle fullscreen                                         |
| <kbd>super + m</kbd>                    | Toggle maximize                                           |
| <kbd>super + n</kbd>                    | Minimize                                                  |
| <kbd>ctrl + super + n</kbd>             | Restore minimized                                         |
| <kbd>alt + tab</kbd>                    | Window switcher                                           |

<br>

**Mouse on the desktop**

| Mousebind          | Action                                     |
|--------------------|--------------------------------------------|
| `left click`       | Dismiss all notifications                  |
| `right click`      | Main menu                                  |
| `middle click`     | Toggle central panel                       |
| `scroll up/down`   | Cycle through tags                         |

*For more information check `awesome/configuration/keys.lua`*

</details>

<details>
<summary><strong>VSCode</strong></summary>

<div align="left">
    <img src="https://user-images.githubusercontent.com/93292023/167767089-87dafa0c-159a-4d1b-bfc2-12ef5de12b7c.png" alt="Preview" width="500px">
</div>

### :milky_way: ‎ <samp>Aesthetic VSCode</samp>

Setup:

1. Install required extension
    - [Customize UI](https://marketplace.visualstudio.com/items?itemName=iocave.customize-ui)
    - [Carbon Product Icons](https://marketplace.visualstudio.com/items?itemName=antfu.icons-carbon)

    note: You can use any themes, but some of the colors will be overwritten by mine
2. copy config file
    ```sh
    cp misc/vscode/User/settings.json ~/.config/Code/User

    ```

</details>

<!-- HISTORY -->
## :japan: ‎ <samp>History</samp>

This started since when im feel bored, idk why i do this things, i love it but ahhh nvm,
but basically im doing this just for fun and also to satisfy myself ofc,
and also look for a lot of [stargazers](https://github.com/rxyhn/dotfiles/stargazers) for sure.
so if you `like` or are `using` these dotfiles you should give this **repo** a `star` right now!
so i'll be more enthusiastic to make other beautiful and aesthetics things!

Thank you! <3

[![Stargazers over time](https://starchart.cc/rxyhn/dotfiles.svg)](https://starchart.cc/rxyhn/dotfiles)

<!-- TIP JAR -->
## :money_with_wings: ‎ <samp>TIP JAR</samp>

If you enjoyed it and would like to show your appreciation, you may want to tip me here.

It is never required but always appreciated.

Thanks from the bottom of my heart! ‎ :heartpulse:

[![](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/rxyhn)

<!-- ACKNOWLEDGEMENTS -->
## :bulb: ‎ <samp>Acknowledgements</samp>

- **Special thanks to**
    - [`awesome-widgets`](https://github.com/streetturtle/awesome-wm-widgets)
    - [`JavaCafe01`](https://github.com/JavaCafe01)
    - [`andOrlando`](https://github.com/andOrlando/awesome-widgets)
    - [`actionless`](https://github.com/actionless)
    - [`Aire-One`](https://github.com/Aire-One)
    - [`elenapan`](https://github.com/elenapan)
    - [`manilarome`](https://github.com/manilarome)
    - [`Mofiqul`](https://github.com/Mofiqul)
<br>

<p align="center"><img src="https://raw.githubusercontent.com/catppuccin/catppuccin/dev/assets/footers/gray0_ctp_on_line.svg?sanitize=true" /></p>
<p align="center"><a href="https://github.com/rxyhn/AwesomeWM-Dotfiles/blob/main/.github/LICENSE"><img src="https://img.shields.io/static/v1.svg?style=flat-square&label=License&message=GPL-3.0&logoColor=eceff4&logo=github&colorA=061115&colorB=67AFC1"/></a></p>