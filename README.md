<img src="https://github.com/vinceliuice/Sierra-gtk-theme/blob/imgs/logo.png" alt="Logo" align="right" /> WhiteSur Gtk Theme
======

WhiteSur is a MacOS Big Sur like theme for GTK 3, GTK 2 and Gnome-Shell which supports GTK 3 and GTK 2 based desktop environments like Gnome, Pantheon, XFCE, Mate, etc.

## Info

### GTK+ 3.20 or later

### GTK2 engines requirements
- GTK2 engine Murrine 0.98.1.1 or later.
- GTK2 pixbuf engine or the gtk(2)-engines package.

Fedora/RedHat distros:

    dnf install gtk-murrine-engine gtk2-engines

Ubuntu/Mint/Debian distros:

    sudo apt install gtk2-engines-murrine gtk2-engines-pixbuf

ArchLinux:

    pacman -S gtk-engine-murrine gtk-engines


### Installation Depends requirement
- sassc.
- optipng.
- inkscape.
- libglib2.0-dev-bin `ubuntu 20.04`
- libglib2.0-dev. `ubuntu 18.04` `debian 10.03` `linux mint 19`
- libxml2-utils. `ubuntu 18.04` `debian 10.03` `linux mint 19`
- glib2-devel. `Fedora` `Redhat`

Fedora/RedHat distros:

    dnf install sassc optipng inkscape glib2-devel

Ubuntu/Mint/Debian distros:

    sudo apt install sassc optipng inkscape libglib2.0-dev-bin

Debian 10:

    sudo apt install sassc optipng inkscape libcanberra-gtk-module libglib2.0-dev libxml2-utils

ArchLinux:

    pacman -S sassc optipng inkscape

Other:
1. Search for the dependencies in your distribution's repository or install the dependencies from source.
2. For CentOS 8 users: the `sassc` package doesn't exist in EPEL 8 or any other main repositories. Download the RPM manually from older EPEL repositories or build from source.

## Installation

### From source

After all the dependencies are installed, you can Run

    ./install.sh

#### Install tips

Usage:  `./Install`  **[OPTIONS...]**

|  OPTIONS:           | |
|:--------------------|:-------------|
|-d, --dest           | Specify theme destination directory (Default: $HOME/.themes)|
|-n, --name           | Specify theme name (Default: WhiteSur)|
|-c, --color          | Specify theme color variant(s) **[light/dark]** (Default: All variants)|
|-o, --opacity        | Specify theme opacity variant(s) **[standard/solid]** (Default: All variants)|
|-a, --alt            | Specify titlebutton variant(s) **[standard/alt]** (Default: All variants)|
|-t, --theme          | Run a terminal dialog to change the theme accent color (Default: blue)|
|-p, --panel          | Run a terminal dialog to change the panel transparency (Default: 85%)|
|-s, --size           | Run a terminal dialog to change the nautilus sidebar width size (Default: 200px)|
|-i, --icon           | activities icon variant(s) **[standard/normal/gnome/ubuntu/arch/manjaro/fedora/debian/void]** (Default: standard variant)|
|-g, --gdm            | Install GDM theme, you should run this with sudo!|
|-r, --remove         | remove theme, this will remove all installed themes!|
|-h, --help           | Show this help|

If you want to change the nautilus sidebar width size,
(Nautilus cannot change the structure of the sidebar, so I added a picture as a background to achieve the effect of bigsur)
then you can run:

    ./install.sh -s

If you want to change the panel transparency, then you can run:

    ./install.sh -p

If you want to remove all installed themes, then you can run:

    ./install.sh -r

If you want to remove installed gdm theme, then you can run:

    ./install.sh -r -g

### On Snapcraft

<a href="https://snapcraft.io/whitesur-gtk-theme">
<img alt="Get it from the Snap Store" src="https://snapcraft.io/static/images/badges/en/snap-store-black.svg" />
</a>

You can install the theme from the Snap Store оr by running:

```
sudo snap install whitesur-gtk-theme
```
To connect the theme to an app run:
```
sudo snap connect [other snap]:gtk-3-themes whitesur-gtk-theme:gtk-3-themes
```
```
sudo snap connect [other snap]:icon-themes whitesur-gtk-theme:icon-themes
```
To connect the theme to all apps which have available plugs to gtk-common-themes you can run:
```
for i in $(snap connections | grep gtk-common-themes:gtk-3-themes | awk '{print $2}'); do sudo snap connect $i whitesur-gtk-theme:gtk-3-themes; done
```

### Suggested themes
|  Suggested themes   | links | preview |
|:--------------------|:-------------|:-------------|
| Kde theme           | [WhiteSur-kde](https://github.com/vinceliuice/WhiteSur-kde)| ![kde](pictures/whitesur-kde-theme.png) |
| Icon theme          | [WhiteSur-icon](https://github.com/vinceliuice/WhiteSur-icon-theme)| ![icon](pictures/whitesur-icon-theme.png) |
| Wallpaper           | [WhiteSur wallpaper](https://github.com/vinceliuice/WhiteSur-kde/tree/master/wallpaper)| ![wallpaper](pictures/whitesur-wallpaper.png) |
| Firefox theme       | [WhiteSur firefox theme](src/other/firefox)| ![firefox](pictures/firefox-theme.png) |
| Dash to Dock theme  | [WhiteSur dash-to-dock theme](src/other/dash-to-dock)| ![firefox](pictures/dash-to-dock.png) |

## Theme Preview
![gtk](pictures/preview-gtk.png)
