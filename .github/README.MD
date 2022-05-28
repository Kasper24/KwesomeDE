<!-- DOTFILES BANNER -->
<p align="center">
  <img width="25%" src="https://github.com/Kasper24.png" />
</p>

<p align="center">
  <b>🎀 KwesomeDE 🎀</b>
</p>

<p align="center">
<a href="#wrench--setup"><img width="150px" style="padding: 0 10px;" src="assets/setup.png"></a>
<a href="https://github.com/Kasper24/KwesomeDE/wiki"><img width="150px" style="padding: 0 10px;" src="assets/wiki.png"></a>
<a href="#ocean--gallery"><img width="150px" style="padding: 0 10px;" src="assets/gallery.png"></a>
<a href="#money_with_wings--tip-jar"><img width="150px" style="padding: 0 10px;" src="assets/tipjar.png"></a>
</p>


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
    <tr>
    <td><img src="assets/7.png" </td>
    <td><img src="assets/8.png" </td>
    <td><img src="assets/9.png" </td>
  </tr>
 </table>

## Thanks for dropping by!

<b> Welcome to my AwesomeWM configuration files, aka KwesomeDE.</b>

The [setup section](#setup) will guide you through the installation process.
AwesomeWM is the most powerful and highly configurable, next generation framework window manager for X,
Although it takes time and effort to configure it, but I'm very satisfied with the result.

<!-- INFORMATION -->
## :snowflake: ‎ <samp>Information</samp>

Here are some details about my setup:

- **OS:** [Arch Linux](https://archlinux.org)
- **WM:** [awesome](https://github.com/awesomeWM/awesome)
- **Terminal:** [kitty](https://github.com/alacritty/alacritty)
- **Shell:** [zsh](https://www.zsh.org/)
- **Editor:** [vscode](https://github.com/microsoft/vscode)
- **Compositor:** [picom-dccsillag](https://github.com/dccsillag/picom/tree/implement-window-animations)
- **Music Player** [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp)

Main Features:
- **Wi-Fi Applet**
- **Bluetooth Applet**
- **Audio Applet**
- **CPU Applet**
- **RAM Applet**
- **Disk Applet**
- **Introduction/Setup tool**
- **Screenshot tool**
- **Recorder tool**
- **Theme Manager**
- **Desktop Icons**
- **Control Panel**
- **Message Panel**
- **Info Panel**
- **Main Menu**
- **Client Menu**
- **App Launcher**
- **Lock Screen**
- **Power/Exit Screen**
- **Window Switcher**
- **Notifications for various system events**
- **Titlebars**
- **Ncmpcpp Custom UI**
- **Many more!**

AwesomeWM Modules:
- **[bling](https://github.com/blingcorp/bling)**
   + Adds new layouts, modules, and widgets that try to primarily focus on window management
- **[layout-machi](https://github.com/xinhaoyuan/layout-machi)**
   + Manual layout for Awesome with an interactive editor
- **[color](https://github.com/andOrlando/color)**
   + Contains a bunch of useful function for conversion as well as well as a very nice api for just colors in general.

<!-- SETUP -->
## :wrench: ‎ <samp>Setup</samp>

<details>
<summary><b>1. Install AwesomeWM</b></summary>

Install the [git version of AwesomeWM](https://github.com/awesomeWM/awesome/).

**Arch users** can use the [awesome-git AUR package](https://aur.archlinux.org/packages/awesome-git/).
   ```sh
   yay/paru -S awesome-git
   ```

**For other distros**, build instructions are [here](https://github.com/awesomeWM/awesome/#building-and-installation).
</details>

<details>
<summary><b>2. Install Dependencies</b></summary>

| Dependency                              | Why/Where is it needed?                                   |
|-----------------------------------------|-----------------------------------------------------------|
| networkmanager                          | Network notifcations, applet/wibar widget                 |
| blueman                                 | Bluetooth notifcations, applet/wibar widget               |
| pactl                                   | Audio notifcations, applet/wibar widget                   |
| pipewire+pipewire-pulse/pulsaudio       | Used by pactl                                             |
| lm_sensors                              | CPU Temperature                                           |
| inotify-tools                           | Daemons that monitor filesystem events                    |
| redshift                                | Blue light toggle                                         |
| maim                                    | Screenshot widget                                         |
| flameshot                               | Screenshot widget                                         |
| ffmpeg                                  | Record widget                                             |
| xdotool                                 | Menu commands use this to input text into terminal        |
| xclip                                   | Copy screenshot into clipboard/paste text into prompt     |
| farge                                   | Color picker keybind                                      |
| upower                                  | Battery notifications/widgets                             |
| picom                                   | Compositor widget/notifcations                            |
| brightnessctl                           | Brightness daemon and widget                              |
| playerctl                               | Media daemon and controls                                 |
| fortune-mod                             | Fortune daemon (right now that daemon is unused)          |
| xfce4-settings                          | Used in the main menu                                     |
| imagemagick                             | Used to generate colors from wallpapers                   |

**Arch Linux (and other Arch-based distributions)**
   ```sh
      pacman -Sy kitty networkmanager blueman pipewire pipewire-pulse lm_sensors inotify-tools
      redshift maim ffmpeg xdotool xclip upower brightnessctl playerctl fortune-mod flameshot xfce4-settings --needed
   ```
   Assuming your **AUR Helper** is [yay](https://github.com/Jguer/yay) or [paru](https://github.com/Morganamilo/paru).
   ```sh
      yay/paru -Sy picom-animations-git farge-git --needed
   ```
</details>

<details>
<summary><b>3. Install Fonts</b></summary>

   + **Font Awesome 6 Pro**              - PAID
   + **Nerd Font Mono**              - [here](https://github.com/ryanoasis/nerd-fonts)
   + **Iosevka**       - [here](https://github.com/be5invis/Iosevka)
   + **Oswald**   - [here](https://fonts.google.com/specimen/Oswald)

Once you download them and unpack them, place them into `~/.fonts` or `~/.local/share/fonts`

And run this command for your system to detect the newly installed fonts.

   ```sh
   fc-cache -v
   ```
</details>


<details>
<summary><b>4. Install KwesomeDE</b></summary>
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
</details>

<!-- GALLERY -->
## :ocean: ‎ <samp>Gallery</samp>

| <b>Action Panel </b> |
| --- |
| <img src="assets/action_panel.gif" width="500px" alt="action panel preview"> |

| <b>Message Panel </b> |
| --- |
| <img src="assets/message_panel.gif" width="500px" alt="message panel preview"> |

| <b>Info Panel </b> |
| --- |
| <img src="assets/info_panel.gif" width="500px" alt="info panel preview"> |

| <b>Wi-Fi Applet</b> |
| --- |
| <img src="assets/wifi_applet.gif" width="500px" alt="wifi applet preview"> |

| <b>Bluetooth Applet</b> |
| --- |
| <img src="assets/bluetooth_applet.gif" width="500px" alt="bluetooth applet preview"> |

| <b>Audio Applet</b> |
| --- |
| <img src="assets/audio_applet.gif" width="500px" alt="audio applet preview"> |

| <b>CPU Applet</b> |
| --- |
| <img src="assets/cpu_applet.gif" width="500px" alt="cpu applet preview"> |

| <b>Theme Manager</b> |
| --- |
| <img src="assets/theme_manager.gif" width="500px" alt="theme manager preview"> |

| <b>Screenshot Tool</b> |
| --- |
| <img src="assets/screenshot.gif" width="500px" alt="screenshot preview"> |

| <b>Recorder Tool</b> |
| --- |
| <img src="assets/recorder.gif" width="500px" alt="recorder preview"> |

| <b>Power Screen</b> |
| --- |
| <img src="assets/power_screen.gif" width="500px" alt="power screen preview"> |

| <b>Lock Screen</b> |
| --- |
| <img src="assets/lock_screen.gif" width="500px" alt="lock screen preview"> |

| <b>Main Menu</b> |
| --- |
| <img src="assets/main_menu.gif" width="500px" alt="main menu preview"> |

| <b>Client Menu</b> |
| --- |
| <img src="assets/client_menu.gif" width="500px" alt="client menu preview"> |

| <b>Notification</b> |
| --- |
| <img src="assets/notification.gif" width="500px" alt="notification preview"> |

| <b>ncmpcpp</b> |
| --- |
| <img src="assets/ncmpcpp.gif" width="500px" alt="ncmpcpp preview"> |

<!-- ACKNOWLEDGEMENTS -->
## :bulb: ‎ <samp>Acknowledgements</samp>

- **Special thanks to**
    - [`rxyhn`](https://github.com/rxyhn/dotfiles)
    - [`awesome-widgets`](https://github.com/streetturtle/awesome-wm-widgets)
    - [`JavaCafe01`](https://github.com/JavaCafe01)
    - [`andOrlando`](https://github.com/andOrlando/awesome-widgets)
    - [`actionless`](https://github.com/actionless)
    - [`Aire-One`](https://github.com/Aire-One)
    - [`elenapan`](https://github.com/elenapan)
    - [`manilarome`](https://github.com/manilarome)
    - [`Mofiqul`](https://github.com/Mofiqul)
<br>