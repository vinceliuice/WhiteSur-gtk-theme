#! /usr/bin/env bash

readonly REPO_DIR="$(dirname "$(readlink -m "${0}")")"
readonly RELEASE_DIR="${REPO_DIR}/release"
source "${REPO_DIR}/shell/lib-install.sh"

# Customization, default values
colors=("${COLOR_VARIANTS[@]}")
opacities=("${OPACITY_VARIANTS[@]}")

C_VARIANTS=('-Light' '-Dark')
S_VARIANTS=('' '-solid')

install() {
  remove_themes; customize_theme; avoid_variant_duplicates
  install_themes; echo; prompt -s "Install Gnome${RELEASE_VERSION} version finished!"; echo
}

compress() {
  for color in "${C_VARIANTS[@]}"; do
    for solid in "${S_VARIANTS[@]}"; do
      rm -rf ${RELEASE_DIR}/${THEME_NAME}${color}${solid}${RELEASE_VERSION}.tar.xz
    done
  done

  cd ${THEME_DIR}

  for color in "${C_VARIANTS[@]}"; do
    for solid in "${S_VARIANTS[@]}"; do
      tar -Jcf ${RELEASE_DIR}/${THEME_NAME}${color}${solid}${RELEASE_VERSION}.tar.xz ${THEME_NAME}${color}${solid}
    done
  done
}

#GNOME_VERSION="3-28"
#RELEASE_VERSION="-3-38"
#install && compress
#prompt -s "Compress Gnome${RELEASE_VERSION} version finished!"; echo

GNOME_VERSION="44-0"
RELEASE_VERSION="-44-0"
install && compress
prompt -s "Compress Gnome${RELEASE_VERSION} version finished!"; echo

prompt -s "Done!"; echo
exit 0
