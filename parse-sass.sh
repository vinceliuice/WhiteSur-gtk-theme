#! /usr/bin/env bash

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SRC_DIR="${REPO_DIR}/src"

# Check command availability
function has_command() {
  command -v $1 > /dev/null
}

if [ ! "$(which sassc 2> /dev/null)" ]; then
  echo sassc needs to be installed to generate the css.
  if has_command zypper; then
    sudo zypper in sassc
  elif has_command apt; then
    sudo apt install sassc
  elif has_command dnf; then
    sudo dnf install -y sassc
  elif has_command yum; then
    sudo yum install sassc
  elif has_command pacman; then
    sudo pacman -S --noconfirm sassc
  fi
fi

SASSC_OPT="-M -t expanded"

_COLOR_VARIANTS=('-Light' '-Dark')
if [ ! -z "${COLOR_VARIANTS:-}" ]; then
  IFS=', ' read -r -a _COLOR_VARIANTS <<< "${COLOR_VARIANTS:-}"
fi

for color in "${_COLOR_VARIANTS[@]}"; do
  sassc $SASSC_OPT src/main/gtk-3.0/gtk${color}.{scss,css}
  echo "==> Generating the 3.0 gtk${color}.css..."
  sassc $SASSC_OPT src/main/gtk-4.0/gtk${color}.{scss,css}
  echo "==> Generating the 4.0 gtk${color}.css..."
  sassc $SASSC_OPT src/main/gnome-shell/shell-3-28/gnome-shell${color}.{scss,css}
  echo "==> Generating the 3.28 gnome-shell${color}.css..."
  sassc $SASSC_OPT src/main/gnome-shell/shell-40-0/gnome-shell${color}.{scss,css}
  echo "==> Generating the 40.0 gnome-shell${color}.css..."
  sassc $SASSC_OPT src/main/gnome-shell/shell-42-0/gnome-shell${color}.{scss,css}
  echo "==> Generating the 42.0 gnome-shell${color}.css..."
  sassc $SASSC_OPT src/main/gnome-shell/shell-44-0/gnome-shell${color}.{scss,css}
  echo "==> Generating the 44.0 gnome-shell${color}.css..."
  sassc $SASSC_OPT src/main/gnome-shell/shell-46-0/gnome-shell${color}.{scss,css}
  echo "==> Generating the 46.0 gnome-shell${color}.css..."
  sassc $SASSC_OPT src/main/gnome-shell/shell-47-0/gnome-shell${color}.{scss,css}
  echo "==> Generating the 47.0 gnome-shell${color}.css..."
  sassc $SASSC_OPT src/main/cinnamon/cinnamon${color}.{scss,css}
  echo "==> Generating the cinnamon${color}.css..."
done
