#! /usr/bin/env bash

GR_FILE="/usr/share/gnome-shell/gnome-shell-theme.gresource"

backup_file() {
  if [[ -f "${1}.bak" || -d "${1}.bak" ]]; then
    rm -rf "${1}"
  fi

  if [[ -f "${1}" || -d "${1}" ]]; then
    mv -n "${1}"{"",".bak"}
  fi
}

./parse-sass.sh

./make_gresource.sh

backup_file "$GR_FILE"

sudo cp -r gnome-shell-theme.gresource "$GR_FILE"

