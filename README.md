<h1 align="center"> WhiteSur GTK Theme </h1>
<p align="center"> <img src="docs/macbook.png"/> </p>

<br>
<p align="center"> <b> A macOS BigSur-like theme for your GTK apps </b> </p>
<br>

# Installation is easy!
<details> <summary> Required dependencies info for nerds </summary>

### Gtk2 theme required
- gtk-murrine-engine     `Fedora/RedHat`
- gtk2-engines-murrine   `Ubuntu/Mint/Debian`
- gtk-engine-murrine     `Arch/Manjaro`

### Install from source required
- sassc
- libglib2.0-dev-bin     `ubuntu 20.04`
- libglib2.0-dev         `ubuntu 18.04` `debian 10.03` `linux mint 19`
- libxml2-utils          `ubuntu 18.04` `debian 10.03` `linux mint 19`
- glib2-devel            `Fedora` `Redhat`

### Theme tweaks required
- imagemagick            `(optional for Gdm theme tweaks)`
- dialog                 `(optional for installation in dialog mode)`
- optipng                `(optional for asset rendering)`
- inkscape               `(optional for asset rendering)`

Don't worry, WhiteSur installer already provides all of those dependencies.
</details>

<details> <summary> Recommended gnome-shell extensions </summary>

- [floating-dock](https://extensions.gnome.org/extension/3730/floating-dock) `Gnome-shell <= 3.38`
- [dash-to-dock](https://extensions.gnome.org/extension/307/dash-to-dock) `Gnome-shell <= 3.38`
- [dash-to-dock](https://github.com/ewlsh/dash-to-dock/tree/ewlsh/gnome-40) `Gnome-shell >= 40.0`
- [blur-my-shell](https://extensions.gnome.org/extension/3193/blur-my-shell)

</details>

## Quick install

### Use the stable package
You can choose the compressed file [compiled in stable version](stable-release) and unzip it to the theme folder `~/.themes` under the user folder.

### Compile from source
You can run `./install.sh` to install the default WhiteSur GTK theme pack which includes
GNOME Shell (Pantheon), Cinnamon, XFWM (XFCE), Metacity, and Plank themes.

## There's so many customizations you can do!
Usage:  `./install.sh [OPTIONS...]`

<details> <summary> Install OPTIONS </summary>

```bash
-d, --dest [DIR] # Set destination directory. Default is '/home/vince/.themes'

-n, --name [NAME] # Set theme name. Default is 'WhiteSur'

-o, --opacity [normal|solid] # Set theme opacity variants. Repeatable. Default is all variants

-c, --color [light|dark] # Set theme color variants. Repeatable. Default is all variants

-a, --alt [normal|alt|all] # Set window control buttons variant. Repeatable. Default is 'normal'

-t, --theme [default|blue|purple|pink|red|orange|yellow|green|grey|all] # Set theme accent color. Repeatable. Default is BigSur-like theme

-p, --panel [default|30|45|60|75] # Set panel transparency. Default is 15%

-s, --size [default|220|240|260|280] # Set Nautilus sidebar minimum width. Default is 200px

-i, --icon [standard|simple|gnome|ubuntu|arch|manjaro|fedora|debian|void] # Set 'Activities' icon. Default is 'standard'

-b, --background [default|blank|IMAGE_PATH] # Set gnome-shell background image. Default is BigSur-like wallpaper

-N, --nautilus-style [default|stable|mojave|glassy] # Set Nautilus style. Default is stable (stabled sidebar)

--round, --roundedmaxwindow # Set maximized window to rounded. Default is square

--right, --rightplacement # Set Nautilus titlebutton placement style to right. Default is left

--normal, --normalshowapps # Set gnome-shell show apps button style to normal. Default is bigsur

--dialog, --interactive # Run this installer interactively, with dialogs.

-r, --remove, -u, --uninstall # Remove all installed WhiteSur themes.

-h, --help # Show this help.
```

</details>

### <p align="center"> <b> Change theme color and accent </b> </p>
<p align="center"> <img src="docs/colors-themes.png"/> </p>

#### Install theme color
Parameter: `--color` `-c` (repeatable)

Example:

```bash
./install.sh -c light          # install light theme color only
./install.sh -c dark -c light  # install dark and light theme colors
```

#### Install theme accent
Parameter: `--theme` `-t` (repeatable)

Example:

```bash
./install.sh -t red            # install red theme accent only
./install.sh -t red -t green   # install red and green theme accents
./install.sh -t all            # install all available theme accents
```

### <p align="center"> <b> Change Nautilus sidebar minimum width </b> </p>
<p align="center"> <img src="docs/sidebars.png"/> </p>

Parameter: `--sidebar` `-s`

Example: `./install.sh -s 220`


### <p align="center"> <b> Change GNOME Shell 'Activities' icon </b> </p>
<p align="center"> <img src="docs/icons.png"/> </p>

Parameter: `--icon` `-i`

Example: `./install.sh -i fedora`


### <p align="center"> <b> Change Nautilus style </b> </p>
<p align="center"> <img src="docs/nautilus.png"/> </p>

Parameter: `--nautilus-style` `-N`

Example: `./install.sh -N mojave`


### <p align="center"> <b> Explore more customization features! </b> </p>
You can run `./install.sh -h` to explore more customization features we have
like changing panel opacity, theme opacity (normal and solid variant), window
control button variant, etc.


# Let's tweak!
Usage:  `./tweaks.sh [OPTIONS...]`

<details> <summary> TWEAKS OPTIONS </summary>

```bash
-f, --firefox
# Install 'WhiteSur' theme for Firefox and connect it to the current Firefox profiles.

-e, --edit-firefox
# Edit 'WhiteSur' theme for Firefox settings and also connect the theme to the current Firefox profiles.

-F, --flatpak
# Connect 'WhiteSur' theme to Flatpak.

-s, --snap
# Connect 'WhiteSur' theme the currently installed snap apps.

-g, --gdm
# Install 'WhiteSur' theme for GDM. Requires to run this shell as root

-d, --dash-to-dock
# Install 'WhiteSur' theme for Dash to Dock and connect it to the current Dash to Dock installation(s).

-N, --no-darken
# Don't darken 'WhiteSur' GDM theme background image.

-n, --no-blur
# Don't blur 'WhiteSur' GDM theme background image.

-b, --background [default|blank|IMAGE_PATH]
# Set 'WhiteSur' GDM theme background image. Default is BigSur-like wallpaper

-o, --opacity [normal|solid]
# Set 'WhiteSur' GDM theme opacity variants. Default is 'normal'

-c, --color [light|dark]
# Set 'WhiteSur' GDM and Dash to Dock theme color variants. Default is 'light'

-t, --theme [default|blue|purple|pink|red|orange|yellow|green|grey]
# Set 'WhiteSur' GDM theme accent color. Default is BigSur-like theme

-p, --panel [default|30|45|60|75]
# Set 'WhiteSur' GDM (GNOME Shell) theme panel transparency. Default is 15%

-i, --icon [standard|simple|gnome|ubuntu|arch|manjaro|fedora|debian|void]
# Set 'WhiteSur' GDM (GNOME Shell) 'Activities' icon. Default is 'standard'

-r, --remove, --revert
# Revert to the original themes, do the opposite things of install and connect.

-h, --help
# Show this help.
```

</details>

## There's more themes you can try!
### <p align="center"> <b> Install and edit Firefox theme </b> </p>
<p align="center"> <img src="docs/firefox.png"/> </p>

#### Install Firefox theme
Parameter: `--firefox` `-f`

Example: `./tweaks.sh -f`

#### Edit Firefox theme
Parameter: `--edit-firefox` `-e`

Example:

```bash
./tweaks.sh -f -e  # install and edit Firefox theme
./tweaks.sh -e -f  # it's reversible!
./tweaks.sh -e     # edit the installed Firefox theme
```

### <p align="center"> <b> Install and customize Dash to Dock theme </b> </p>
<p align="center"> <img src="docs/dash-to-dock.png"/> </p>

#### Install Dash to Dock theme
Parameter: `--dash-to-dock` `-d`

Example: `./tweaks.sh -d`

#### Change its color
Parameter: `--color` `-c`

Example: `./tweaks.sh -d -c dark`

### <p align="center"> <b> Install and customize GDM theme </b> </p>
<p align="center"> <img src="docs/gdm.png"/> </p>

#### Install GDM theme
Parameter: `--gdm` `-g` (requires to be ran as root)

Example: `sudo ./tweaks.sh -g`

#### Change the background
Parameter: `--background` `-b`

Example:

```bash
sudo ./tweaks.sh -g -b "my picture.jpg" # use the custom background
sudo ./tweaks.sh -g -b default          # use the default background
sudo ./tweaks.sh -g -b blank            # make it blank
```

#### Make the background not darker (normal)
Parameter: `--no_darken` `-N`

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

## Using WhiteSur theme on app sandboxing platforms
<p align="center"> <img src="docs/sandboxes.png"/> </p>

### <p align="center"> <b> Connect WhiteSur theme to Flatpak </b> </p>
Parameter: `--flatpak` `-F`

Example: `./tweaks.sh -F`

### <p align="center"> <b> Connect WhiteSur theme to your Snap apps </b> </p>
Parameter: `--snap` `-s`

Example: `./tweaks.sh -s`

Note:

> This can only connect WhiteSur theme to your currently installed Snap
> apps. You may need to run this command again to connect to your newly installed
> Snap apps

# Other recommended stuffs
## Whitesur KDE Theme
<p align="center"> <a href="https://github.com/vinceliuice/WhiteSur-kde">
  <img src="docs/whitesur-kde-theme.png"/>
</a> </p>
<br>
<p align="center"> <a href="https://github.com/vinceliuice/WhiteSur-kde">
  <img src="docs/download-button.png"/>
</a> </p>
<br>

## Whitesur Icon Theme
<p align="center"> <a href="https://github.com/vinceliuice/WhiteSur-icon-theme">
  <img src="docs/whitesur-icon-theme.png"/>
</a> </p>
<br>
<p align="center"> <a href="https://github.com/vinceliuice/WhiteSur-icon-theme">
  <img src="docs/download-button.png"/>
</a> </p>
<br>

## Whitesur Wallpaper
<p align="center"> <a href="https://github.com/vinceliuice/WhiteSur-kde/tree/master/wallpaper">
  <img src="docs/whitesur-wallpaper.png"/>
</a> </p>
<br>
<p align="center"> <a href="https://github.com/vinceliuice/WhiteSur-kde/tree/master/wallpaper">
  <img src="docs/download-button.png"/>
</a> </p>
<br><br>

# Technical details and getting involved
Please go read [CONTRIBUTING.md](CONTRIBUTING.md) for more info
