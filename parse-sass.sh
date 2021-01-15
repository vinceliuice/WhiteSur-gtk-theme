#! /usr/bin/env bash

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

_COLOR_VARIANTS=('-light' '-dark')
if [ ! -z "${COLOR_VARIANTS:-}" ]; then
  IFS=', ' read -r -a _COLOR_VARIANTS <<< "${COLOR_VARIANTS:-}"
fi

_TRANS_VARIANTS=('' '-solid')
if [ ! -z "${TRANS_VARIANTS:-}" ]; then
  IFS=', ' read -r -a _TRANS_VARIANTS <<< "${TRANS_VARIANTS:-}"
fi

_ALT_VARIANTS=('' '-alt')
if [ ! -z "${TRANS_VARIANTS:-}" ]; then
  IFS=', ' read -r -a _TRANS_VARIANTS <<< "${TRANS_VARIANTS:-}"
fi

_THEME_VARIANTS=('' '-blue' '-purple' '-pink' '-red' '-orange' '-yellow' '-green' '-grey')
if [ ! -z "${THEME_VARIANTS:-}" ]; then
  IFS=', ' read -r -a _THEME_VARIANTS <<< "${THEME_VARIANTS:-}"
fi

for color in "${_COLOR_VARIANTS[@]}"; do
  for trans in "${_TRANS_VARIANTS[@]}"; do
    for theme in "${_THEME_VARIANTS[@]}"; do
      sassc $SASSC_OPT src/main/gtk-3.0/gtk${color}${trans}${theme}.{scss,css}
      echo "==> Generating the gtk${color}${trans}${theme}.css..."
      sassc $SASSC_OPT src/main/cinnamon/cinnamon${color}${trans}${theme}.{scss,css}
      echo "==> Generating the cinnamon${color}${trans}${theme}.css..."
    done
  done
done

for color in "${_COLOR_VARIANTS[@]}"; do
  for trans in "${_TRANS_VARIANTS[@]}"; do
    for alt in "${_ALT_VARIANTS[@]}"; do
      for theme in "${_THEME_VARIANTS[@]}"; do
        sassc $SASSC_OPT src/main/gnome-shell/gnome-shell${color}${trans}${alt}${theme}.{scss,css}
        echo "==> Generating the gnome-shell${color}${trans}${alt}${theme}.css..."
      done
    done
  done
done

for color in "${_COLOR_VARIANTS[@]}"; do
  for theme in "${_THEME_VARIANTS[@]}"; do
    sassc $SASSC_OPT src/main/gnome-shell/gdm3${color}${theme}.{scss,css}
    echo "==> Generating the gdm3${color}${theme}.css..."
  done
done

sassc $SASSC_OPT src/other/dash-to-dock/stylesheet.{scss,css}
echo "==> Generating dash-to-dock stylesheet.css..."
sassc $SASSC_OPT src/other/dash-to-dock/stylesheet-dark.{scss,css}
echo "==> Generating dash-to-dock stylesheet-dark.css..."
