#! /usr/bin/env bash

INKSCAPE="/usr/bin/inkscape"
OPTIPNG="/usr/bin/optipng"

# check command avalibility
has_command() {
  "$1" -v $1 > /dev/null 2>&1
}

if ! has_command inkscape; then
  echo inkscape and optipng needs to be installed to generate the assets.
  if has_command zypper; then
    sudo zypper in inkscape optipng
  elif has_command apt; then
    sudo apt install inkscape optipng
  elif has_command dnf; then
    sudo dnf install -y inkscape optipng
  elif has_command yum; then
    sudo yum install inkscape optipng
  elif has_command pacman; then
    sudo pacman -S --noconfirm inkscape optipng
  fi
fi

echo Rendering gtk-2.0 assets
cd gtk-2.0 && ./render-assets.sh

echo Rendering gtk-3.0 assets
cd gtk-3.0 && ./render-thumbnails.sh
cd gtk-3.0/common-assets && ./render-assets.sh
cd gtk-3.0/windows-assets && ./render-assets.sh && ./render-alt-assets.sh

echo Rendering cinnamon thumbnails
cd cinnamon && ./render-thumbnails.sh

echo Rendering metacity-1 assets
cd metacity-1 && ./render-assets.sh

echo Rendering xfwm4 assets
cd xfwm4 && ./render-assets.sh

exit 0
