<h1 align="center"> WhiteSur GTK Theme </h1>
<p align="center"> <img src="https://github.com/vinceliuice/WhiteSur-gtk-theme/blob/pictures/pictures/macbook.png"/> </p>

<br>
<p align="center"> <b> A macOS BigSur-like theme for your GTK apps </b> </p>
<br>

## Donate

If you like my project, you can buy me a coffee:

<span class="paypal"><a href="https://www.paypal.me/vinceliuice" title="Donate to this project using Paypal"><img src="https://www.paypalobjects.com/webstatic/mktg/Logo/pp-logo-100px.png" alt="PayPal donate button" /></a></span>

# Installation is easy!
<details> <summary> Required dependencies <b>(click to open)</b> </summary>

### "Install from source" deps
- sassc
- libglib2.0-dev-bin     `ubuntu 20.04`
- libglib2.0-dev         `ubuntu 18.04` `debian 10.03` `linux mint 19`
- libxml2-utils          `ubuntu 18.04` `debian 10.03` `linux mint 19`
- glib2-devel            `Fedora` `Redhat`

### Misc deps
- imagemagick            `(optional for GDM theme tweak)`
- dialog                 `(optional for installation in dialog mode)`
- optipng                `(optional for asset rendering)`
- inkscape               `(optional for asset rendering)`

Don't worry, WhiteSur installer already provides all of those dependencies.
</details>

<details> <summary> Recommended GNOME Shell extensions <b>(click to open)</b> </summary>

- [user-themes](https://extensions.gnome.org/extension/19/user-themes/) to enable gnome-shell theme (and not just the application theme)
- [dash-to-dock](https://extensions.gnome.org/extension/307/dash-to-dock)
- [blur-my-shell](https://extensions.gnome.org/extension/3193/blur-my-shell)

</details>

## Quick install

### Installing from source

1. Run `git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1`

2. Run `./install.sh` to install the default WhiteSur GTK theme pack.

### Uninstall

<details> <summary> For example: <b>(click to open)</b> </summary>

- uninstall Gtk themes: `./install.sh -r`
- uninstall GDM theme: `sudo ./tweaks.sh -g -r`
- uninstall Firefox theme: `./tweaks.sh -f -r`

- uninstall Dash-to-dock theme: `./tweaks.sh -d -r`
- uninstall Flatpak Gtk themes: `./tweaks.sh -F -r`
- uninstall Snap Gtk themes: `./tweaks.sh -s -r`

</details>

## There's so many customizations you can do!
Usage:  `./install.sh [OPTIONS...]`

<details> <summary> Options <b>(click to open)</b> </summary>

```bash

  -d, --dest DIR
 Set destination directory. Default is '/home/vince/.themes'

  -n, --name NAME
 Set theme name. Default is 'WhiteSur'

  -o, --opacity [normal|solid]
 Set theme opacity variants. Repeatable. Default is all variants

  -c, --color [Light|Dark]
 Set theme color variants. Repeatable. Default is all variants

  -a, --alt [normal|alt|all]
 Set window control buttons variant. Repeatable. Default is 'normal'

  -t, --theme [default|blue|purple|pink|red|orange|yellow|green|grey|all]
 Set theme accent color. Repeatable. Default is BigSur-like theme

  -p, --panel-opacity [default|30|45|60|75]
 Set panel transparency. Default is 15%

  -P, --panel-size [default|smaller|bigger]
 Set Gnome shell panel height size. Default is 32px

  -s, --size [default|180|220|240|260|280]
 Set Nautilus sidebar minimum width. Default is 200px

  -i, --icon [standard|simple|gnome|ubuntu|tux|arch|manjaro|fedora|debian|void|opensuse|popos|mxlinux|zorin]
 Set 'Activities' icon. Default is 'standard'

  -b, --background [default|blank|IMAGE_PATH]
 Set gnome-shell background image. Default is BigSur-like wallpaper

  -m, --monterey
 Set to MacOS Monterey style.

  -N, --nautilus-style [stable|normal|mojave|glassy]
 Set Nautilus style. Default is BigSur-like style (stabled sidebar)

  -l, --libadwaita
 Install theme into gtk4.0 config for libadwaita. Default is dark version

  -HD, --highdefinition
 Set to High Definition size. Default is laptop size

  --normal, --normalshowapps
 Set gnome-shell show apps button style to normal. Default is bigsur

  --round, --roundedmaxwindow
 Set maximized window to rounded. Default is square

  --right, --rightplacement
 Set Nautilus titlebutton placement to right. Default is left

  --black, --blackfont
 Set panel font color to black. Default is white

  --darker, --darkercolor
 Install darker 'WhiteSur' dark themes.

  --nord, --nordcolor
 Install 'WhiteSur' Nord ColorScheme themes.

  --dialog, --interactive
 Run this installer interactively, with dialogs.

  --silent-mode
 Meant for developers: ignore any confirm prompt and params become more strict.

  -r, --remove, -u, --uninstall
 Remove all installed WhiteSur themes.

  -h, --help
 Show this help.

```

</details>

### Fix for libadwaita (not perfect)

<details> <summary> Details <b>(click to open)</b> </summary>

  Since the release of `Gnome 43.0`, more and more built-in apps use `libadwaita` now, and libadwaita does not support custom themes, which means we cannot change the appearance of app using libadwaita through `gnome-tweaks` or `dconf-editor`. For users who love custom themes, it’s really sucks!

  Anyway if anybody who still want to custom themes we can only do this way:

  that is to use the `theme file` to overwrite the `gtk-4.0 configuration file`. The result is that only Fixed making all gtk4 apps use one theme and cannot be switched (even can not switch to dark mode) If you want to change a theme, you can only re-overwrite the `gtk-4.0 configuration file` with a new theme, I know this method is not perfect, But at the moment it is only possible to continue using themes for libadwaita's apps ...

</details>

Run this command to install `WhiteSur` into `gtk-4.0 configuration folder` ($HOME/.config/gtk-4.0)

```bash
./install.sh -l                # Default is the normal dark theme
./install.sh -l -c Light       # install light theme for libadwaita
```

### Connect WhiteSur theme to Flatpak (Snap not support)
Parameter: `--flatpak` `-F`

Example: `./tweaks.sh -F`

Fix for Flatpak gtk-4.0 app:

```bash
sudo flatpak override --filesystem=xdg-config/gtk-4.0
```

### <p align="center"> <b> Change theme color and accent </b> </p>
<p align="center"> <img src="https://github.com/vinceliuice/WhiteSur-gtk-theme/blob/pictures/pictures/colors-themes.png"/> </p>

#### Install theme color
Parameter: `--color` `-c` (repeatable)

Example:

```bash
./install.sh -c Light          # install light theme color only
./install.sh -c Dark -c Light  # install dark and light theme colors
```

#### Install theme accent
Parameter: `--theme` `-t` (repeatable)

Example:

```bash
./install.sh -t red            # install red theme accent only
./install.sh -t red -t green   # install red and green theme accents
./install.sh -t all            # install all available theme accents
```

### <p align="center"> <b> Change Nautilus style </b> </p>
<p align="center"> <img src="https://github.com/vinceliuice/WhiteSur-gtk-theme/blob/pictures/pictures/nautilus.png"/> </p>

Parameter: `--nautilus-style` `-N`

Example: `./install.sh -N mojave`


### <p align="center"> <b> Explore more customization features! </b> </p>
You can run `./install.sh -h` to explore more customization features we have
like changing panel opacity, theme opacity (normal and solid variant), window
control button variant, etc.


# Let's tweak!
Usage:  `./tweaks.sh [OPTIONS...]`

<details> <summary> Options <b>(click to open)</b> </summary>

```bash

  -g, --gdm [default|x2]
 Install 'WhiteSur' theme for GDM (scaling: 100%/200%, default is 100%). Requires to run this shell as root

  -o, --opacity [normal|solid]
 Set 'WhiteSur' GDM theme opacity variants. Default is 'normal'

  -c, --color [Light|Dark]
 Set 'WhiteSur' GDM and Dash to Dock theme color variants. Default is 'light'

  -t, --theme [default|blue|purple|pink|red|orange|yellow|green|grey]
 Set 'WhiteSur' GDM theme accent color. Default is BigSur-like theme

  -N, --no-darken
 Don't darken 'WhiteSur' GDM theme background image.

  -n, --no-blur
 Don't blur 'WhiteSur' GDM theme background image.

  -b, --background [default|blank|IMAGE_PATH]
 Set 'WhiteSur' GDM theme background image. Default is BigSur-like wallpaper

  -p, --panel-opacity [default|30|45|60|75]
 Set 'WhiteSur' GDM (GNOME Shell) theme panel transparency. Default is 15%

  -P, --panel-size [default|smaller|bigger]
 Set 'WhiteSur' Gnome shell panel height size. Default is 32px

  -i, --icon [standard|simple|gnome|ubuntu|tux|arch|manjaro|fedora|debian|void|opensuse|popos|mxlinux|zorin]
 Set 'WhiteSur' GDM (GNOME Shell) 'Activities' icon. Default is 'standard'

  --nord, --nordcolor
 Install 'WhiteSur' Nord ColorScheme themes.

  -f, --firefox [default|monterey|alt]
 Install 'WhiteSur|Monterey|Alt' theme for Firefox and connect it to the current Firefox profiles. Default is WhiteSur

  -e, --edit-firefox
 Edit 'WhiteSur' theme for Firefox settings and also connect the theme to the current Firefox profiles.

  -F, --flatpak
 Connect 'WhiteSur' theme to Flatpak.

  -d, --dash-to-dock
 Fixed Dash to Dock theme issue.

  -r, --remove, --revert
 Revert to the original themes, do the opposite things of install and connect.

  --silent-mode
 Meant for developers: ignore any confirm prompt and params become more strict.

  -h, --help
 Show this help.

```

</details>

## There's more themes you can try!
### <p align="center"> <b> Install and edit Firefox theme </b> </p>

<p align="center"> <a href="src/other/firefox">
<img src="https://github.com/vinceliuice/WhiteSur-gtk-theme/blob/pictures/pictures/firefox.svg"/>
</a> </p>

#### [Install Firefox theme](src/other/firefox)
Parameter: `--firefox` `-f`

Example: `./tweaks.sh -f`

#### Edit Firefox theme
Parameter: `--edit-firefox` `-e`

Example:

```bash
./tweaks.sh -e           # edit the installed Firefox theme
./tweaks.sh -f -r        # remove installed Firefox theme
./tweaks.sh -f monterey  # install Monterey Firefox theme
```

### <p align="center"> <b> Install and customize GDM theme </b> </p>
<p align="center"> <img src="https://github.com/vinceliuice/WhiteSur-gtk-theme/blob/pictures/pictures/gdm.png"/> </p>

#### Install GDM theme
Parameter: `--gdm` `-g` (requires to be run as root)

Example: `sudo ./tweaks.sh -g`

#### Change the background
Parameter: `--background` `-b`

Example:

```bash
sudo ./tweaks.sh -g -b "my picture.jpg" # use the custom background
sudo ./tweaks.sh -g -b default          # use the default background
sudo ./tweaks.sh -g -b blank            # make it blank
```

#### Don't darken the background
Parameter: `--no-darken` `-N`

Example:

```bash
sudo ./tweaks.sh -g -N                          # darken the default background
sudo ./tweaks.sh -g -N -b "wallpapers/snow.jpg" # darken the custom background
```

#### Don't blur the background
Parameter: `--no-blur` `-n`

Example:

```bash
sudo ./tweaks.sh -g -n                           # don't blur the default background
sudo ./tweaks.sh -g -n -b "wallpapers/rocks.jpg" # don't blur the custom background
```

#### Do more GDM customizations
You can do [the similar customization features in `./install.sh`](#theres-so-many-customizations-you-can-do)
like changing theme color (dark and light variant) and accent, GNOME Shell
'Activities' icon, etc. related to GDM. Run `./tweaks.sh -h` to explore!

## Other recommended stuff
### WhiteSur Icon Theme
<p align="center"> <a href="https://github.com/vinceliuice/WhiteSur-icon-theme">
  <img src="https://github.com/vinceliuice/WhiteSur-gtk-theme/blob/pictures/pictures/icon-theme.png"/>
</a> </p>
<br>
<p align="center"> <a href="https://github.com/vinceliuice/WhiteSur-icon-theme">
  <img src="https://github.com/vinceliuice/WhiteSur-gtk-theme/blob/pictures/pictures/download-button.svg"/>
</a> </p>
<br>

### WhiteSur Wallpapers
<p align="center"> <a href="https://github.com/vinceliuice/WhiteSur-wallpapers">
  <img class="image" src="https://github.com/vinceliuice/WhiteSur-gtk-theme/blob/pictures/pictures/wallpaper.gif"/>
</a> </p>
<br>
<p align="center"> <a href="https://github.com/vinceliuice/WhiteSur-wallpapers">
  <img src="https://github.com/vinceliuice/WhiteSur-gtk-theme/blob/pictures/pictures/download-button.svg"/>
</a> </p>
<br>

## Technical details and getting involved
Please go read [CONTRIBUTING.md](.github/CONTRIBUTING.md) for more info
