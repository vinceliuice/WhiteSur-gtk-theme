#! /bin/bash

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

_COLOR_VARIANTS=('-light' '-dark')
if [ ! -z "${COLOR_VARIANTS:-}" ]; then
  IFS=', ' read -r -a _COLOR_VARIANTS <<< "${COLOR_VARIANTS:-}"
fi

_TRANS_VARIANTS=('' '-solid')
if [ ! -z "${TRANS_VARIANTS:-}" ]; then
  IFS=', ' read -r -a _TRANS_VARIANTS <<< "${TRANS_VARIANTS:-}"
fi

for color in "${_COLOR_VARIANTS[@]}"; do
  for trans in "${_TRANS_VARIANTS[@]}"; do
    sassc $SASSC_OPT src/main/gtk-3.0/gtk${color}${trans}.{scss,css}
    echo "==> Generating the gtk${color}${trans}.css..."
    sassc $SASSC_OPT src/main/gnome-shell/gnome-shell${color}${trans}.{scss,css}
    echo "==> Generating the gnome-shell${color}${trans}.css..."
    sassc $SASSC_OPT src/main/cinnamon/cinnamon${color}${trans}.{scss,css}
    echo "==> Generating the cinnamon${color}${trans}.css..."
  done
done
