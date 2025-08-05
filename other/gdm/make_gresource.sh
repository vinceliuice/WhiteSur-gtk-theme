#! /usr/bin/env bash

# Check command availability
function has_command() {
  command -v $1 > /dev/null
}

if ! has_command glib-compile-resources; then
    echo -e "DEPS: 'glib2.0' are required for theme installation."

    if has_command zypper; then
      sudo zypper in -y glib2-devel
    elif has_command swupd; then
      prepare_swupd && sudo swupd bundle-add libglib
    elif has_command apt; then
      prepare_install_apt_packages libglib2.0-dev-bin
    elif has_command dnf; then
      sudo dnf install -y glib2-devel
    elif has_command yum; then
      sudo yum install -y glib2-devel
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed glib2
    elif has_command xbps-install; then
      prepare_xbps && sudo xbps-install -Sy glib-devel
    elif has_command eopkg; then
      sudo eopkg -y upgrade; sudo eopkg -y install glib2
    fi
fi

glib-compile-resources --sourcedir="theme" --target="gnome-shell-theme.gresource" gnome-shell-theme.gresource.xml

echo finished !
