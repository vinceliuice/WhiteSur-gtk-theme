#!/bin/bash

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WALLPAPER_DIR="$HOME/.local/share/backgrounds"

THEME_VARIANTS=('WhiteSur' 'Monterey')
COLOR_VARIANTS=('' '-light' '-dark')
SCREEN_VARIANTS=('1080p' '2k' '4k')

#COLORS
CDEF=" \033[0m"                               # default color
CCIN=" \033[0;36m"                            # info color
CGSC=" \033[0;32m"                            # success color
CRER=" \033[0;31m"                            # error color
CWAR=" \033[0;33m"                            # waring color
b_CDEF=" \033[1;37m"                          # bold default color
b_CCIN=" \033[1;36m"                          # bold info color
b_CGSC=" \033[1;32m"                          # bold success color
b_CRER=" \033[1;31m"                          # bold error color
b_CWAR=" \033[1;33m"                          # bold warning color

# echo like ...  with  flag type  and display message  colors
prompt () {
  case ${1} in
    "-s"|"--success")
      echo -e "${b_CGSC}${@/-s/}${CDEF}";;    # print success message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;    # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;    # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;    # print info message
    *)
    echo -e "$@"
    ;;
  esac
}

usage() {
  cat << EOF
Usage: $0 [OPTION]...

OPTIONS:
  -t, --theme VARIANT     Specify theme variant(s) [whitesur|monterey] (Default: All variants)s)
  -c, --color VARIANT     Specify color variant(s) [light|dark] (Default: All variants)s)
  -s, --screen VARIANT    Specify screen variant [1080p|2k|4k] (Default: 1080p)
  -u, --uninstall         Uninstall wallpappers
  -h, --help              Show help

INSTALLATION EXAMPLES:
Install WhiteSur dark version on 4k display:
  $0 -t whitesur -c dark -s 4k
EOF
}

install() {
  local theme="$1"
  local color="$2"
  local screen="$3"
  prompt -i "\n * Install ${theme}${color} in ${WALLPAPER_DIR}... "
  mkdir -p "${WALLPAPER_DIR}"
  [[ -f ${WALLPAPER_DIR}/${theme}${color}.png ]] && rm -rf ${WALLPAPER_DIR}/${theme}${color}.png
  cp -r ${REPO_DIR}/${screen}/${theme}${color}.png ${WALLPAPER_DIR}
}

uninstall() {
  local theme="$1"
  local color="$2"
  prompt -i "\n * Uninstall ${theme}${color}... "
  [[ -f ${WALLPAPER_DIR}/${theme}${color}.png ]] && rm -rf ${WALLPAPER_DIR}/${theme}${color}.png
}

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -u|--uninstall)
      uninstall='true'
      shift
      ;;
    -t|--theme)
      shift
      for theme in "$@"; do
        case "$theme" in
          whitesur)
            themes+=("${THEME_VARIANTS[0]}")
            shift 1
            ;;
          monterey)
            themes+=("${THEME_VARIANTS[1]}")
            shift 1
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized color variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -c|--color)
      shift
      for color in "$@"; do
        case "$color" in
          light)
            colors+=("${COLOR_VARIANTS[0]}")
            shift 1
            ;;
          dark)
            colors+=("${COLOR_VARIANTS[1]}")
            shift 1
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized color variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -s|--screen)
      shift
      for screen in "$@"; do
        case "$screen" in
          1080p)
            screens+=("${SCREEN_VARIANTS[0]}")
            shift 1
            ;;
          2k)
            screens+=("${SCREEN_VARIANTS[1]}")
            shift 1
            ;;
          4k)
            screens+=("${SCREEN_VARIANTS[2]}")
            shift 1
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized color variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      prompt -e "ERROR: Unrecognized installation option '$1'."
      prompt -i "Try '$0 --help' for more information."
      exit 1
      ;;
  esac
done

if [[ "${#themes[@]}" -eq 0 ]] ; then
  themes=("${THEME_VARIANTS[@]}")
fi

if [[ "${#colors[@]}" -eq 0 ]] ; then
  colors=("${COLOR_VARIANTS[@]}")
fi

if [[ "${#screens[@]}" -eq 0 ]] ; then
  screens=("${SCREEN_VARIANTS[0]}")
fi

install_wallpaper() {
  for theme in "${themes[@]}"; do
    for color in "${colors[@]}"; do
      for screen in "${screens[@]}"; do
        install "$theme" "$color" "$screen"
      done
    done
  done
}

uninstall_wallpaper() {
  for theme in "${themes[@]}"; do
    for color in "${colors[@]}"; do
      uninstall "$theme" "$color"
    done
  done
}

echo
if [[ "${uninstall}" != 'true' ]]; then
  install_wallpaper
else
  uninstall_wallpaper
fi
prompt -s "\n * All done!"
echo

