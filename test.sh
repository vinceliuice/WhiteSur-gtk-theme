#! /usr/bin/env bash
set -ueo pipefail
set -o physical
#set -x

REPO_DIR=$(cd $(dirname $0) && pwd)
SRC_DIR=${REPO_DIR}/src

ROOT_UID=0
DEST_DIR=

# Destination directory
if [ "$UID" -eq "$ROOT_UID" ]; then
  DEST_DIR="/usr/share/themes"
else
  DEST_DIR="$HOME/.themes"
fi

SASSC_OPT="-M -t expanded"

THEME_NAME=WhiteSur
COLOR_VARIANTS=('-light' '-dark')
OPACITY_VARIANTS=('' '-solid')

# COLORS
CDEF=" \033[0m"                                     # default color
CCIN=" \033[0;36m"                                  # info color
CGSC=" \033[0;32m"                                  # success color
CRER=" \033[0;31m"                                  # error color
CWAR=" \033[0;33m"                                  # warning color
b_CDEF=" \033[1;37m"                                # bold default color
b_CCIN=" \033[1;36m"                                # bold info color
b_CGSC=" \033[1;32m"                                # bold success color
b_CRER=" \033[1;31m"                                # bold error color
b_CWAR=" \033[1;33m"                                # bold warning color

# Echo like ... with flag type and display message colors
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

# Check command availability
function has_command() {
  command -v $1 > /dev/null
}

operation_canceled() {
  clear
  prompt  -i "\n Operation canceled by user, Bye!"
  exit 1
}

usage() {
  printf "%s\n" "Usage: $0 [OPTIONS...]"
  printf "\n%s\n" "OPTIONS:"
  printf "  %-25s%s\n" "-d, --dest DIR" "Specify theme destination directory (Default: ${DEST_DIR})"
  printf "  %-25s%s\n" "-n, --name NAME" "Specify theme name (Default: ${THEME_NAME})"
  printf "  %-25s%s\n" "-g, --gdm" "Install GDM theme, this option needs root user authority! Please run this with sudo"
  printf "  %-25s%s\n" "-r, --remove" "Remove theme, remove all installed themes"
  printf "  %-25s%s\n" "-o, --opacity VARIANTS" "Specify theme opacity variant(s) [standard|solid] (Default: All variants)"
  printf "  %-25s%s\n" "-c, --color VARIANTS" "Specify theme color variant(s) [light|dark] (Default: All variants)"
  printf "  %-25s%s\n" "-h, --help" "Show this help"
}

install() {
  local dest=${1}
  local name=${2}
  local color=${3}
  local opacity=${4}

  [[ ${color} == '-light' ]] && local ELSE_LIGHT=${color}
  [[ ${color} == '-dark' ]] && local ELSE_DARK=${color}

  local THEME_DIR=${1}/${2}${3}${4}

  [[ -d ${THEME_DIR} ]] && rm -rf ${THEME_DIR}

  prompt -i "Installing '${THEME_DIR}'..."

  mkdir -p                                                                              ${THEME_DIR}

  echo "[Desktop Entry]" >>                                                             ${THEME_DIR}/index.theme
  echo "Type=X-GNOME-Metatheme" >>                                                      ${THEME_DIR}/index.theme
  echo "Name=${2}${3}${4}" >>                                                           ${THEME_DIR}/index.theme
  echo "Comment=A MacOS BigSur like Gtk+ theme based on Elegant Design" >>              ${THEME_DIR}/index.theme
  echo "Encoding=UTF-8" >>                                                              ${THEME_DIR}/index.theme
  echo "" >>                                                                            ${THEME_DIR}/index.theme
  echo "[X-GNOME-Metatheme]" >>                                                         ${THEME_DIR}/index.theme
  echo "GtkTheme=${2}${3}${4}" >>                                                       ${THEME_DIR}/index.theme
  echo "MetacityTheme=${2}${3}${4}" >>                                                  ${THEME_DIR}/index.theme
  echo "IconTheme=${2}${3}" >>                                                          ${THEME_DIR}/index.theme
  echo "CursorTheme=${2}${3}" >>                                                        ${THEME_DIR}/index.theme
  echo "ButtonLayout=close,minimize,maximize:menu" >>                                   ${THEME_DIR}/index.theme

  mkdir -p                                                                              ${THEME_DIR}/gnome-shell
  cp -r ${SRC_DIR}/assets/gnome-shell/icons                                             ${THEME_DIR}/gnome-shell
  cp -r ${SRC_DIR}/main/gnome-shell/pad-osd.css                                         ${THEME_DIR}/gnome-shell
  cp -r ${SRC_DIR}/main/gnome-shell/gnome-shell${color}${opacity}.css                   ${THEME_DIR}/gnome-shell/gnome-shell.css
  cp -r ${SRC_DIR}/assets/gnome-shell/common-assets                                     ${THEME_DIR}/gnome-shell/assets
  cp -r ${SRC_DIR}/assets/gnome-shell/assets${color}/*.svg                              ${THEME_DIR}/gnome-shell/assets
  cp -r ${SRC_DIR}/assets/gnome-shell/activities/activities.svg                         ${THEME_DIR}/gnome-shell/assets/activities.svg

  cd "${THEME_DIR}/gnome-shell"
  mv -f assets/no-events.svg no-events.svg
  mv -f assets/process-working.svg process-working.svg
  mv -f assets/no-notifications.svg no-notifications.svg

  mkdir -p                                                                              ${THEME_DIR}/gtk-2.0
  cp -r ${SRC_DIR}/main/gtk-2.0/gtkrc${color}                                           ${THEME_DIR}/gtk-2.0/gtkrc
  cp -r ${SRC_DIR}/main/gtk-2.0/menubar-toolbar${color}.rc                              ${THEME_DIR}/gtk-2.0/menubar-toolbar.rc
  cp -r ${SRC_DIR}/main/gtk-2.0/common/*.rc                                             ${THEME_DIR}/gtk-2.0
  cp -r ${SRC_DIR}/assets/gtk-2.0/assets${color}                                        ${THEME_DIR}/gtk-2.0/assets

  mkdir -p                                                                              ${THEME_DIR}/gtk-3.0
  cp -r ${SRC_DIR}/assets/gtk-3.0/common-assets/assets                                  ${THEME_DIR}/gtk-3.0
  cp -r ${SRC_DIR}/assets/gtk-3.0/common-assets/sidebar-assets/*.png                    ${THEME_DIR}/gtk-3.0/assets
  cp -r ${SRC_DIR}/assets/gtk-3.0/windows-assets/titlebutton                            ${THEME_DIR}/gtk-3.0/windows-assets
  cp -r ${SRC_DIR}/assets/gtk-3.0/thumbnails/thumbnail${color}.png                      ${THEME_DIR}/gtk-3.0/thumbnail.png
  cp -r ${SRC_DIR}/main/gtk-3.0/gtk-dark${opacity}.css                                  ${THEME_DIR}/gtk-3.0/gtk-dark.css

  if [[ ${color} == '-light' ]]; then
    cp -r ${SRC_DIR}/main/gtk-3.0/gtk-light${opacity}.css                               ${THEME_DIR}/gtk-3.0/gtk.css
  else
    cp -r ${SRC_DIR}/main/gtk-3.0/gtk-dark${opacity}.css                                ${THEME_DIR}/gtk-3.0/gtk.css
  fi

  glib-compile-resources --sourcedir=${THEME_DIR}/gtk-3.0 --target=${THEME_DIR}/gtk-3.0/gtk.gresource ${SRC_DIR}/main/gtk-3.0/gtk.gresource.xml
  rm -rf ${THEME_DIR}/gtk-3.0/{assets,windows-assets,gtk.css,gtk-dark.css}
  echo '@import url("resource:///org/gnome/theme/gtk.css");' >>                         ${THEME_DIR}/gtk-3.0/gtk.css
  echo '@import url("resource:///org/gnome/theme/gtk-dark.css");' >>                    ${THEME_DIR}/gtk-3.0/gtk-dark.css

  mkdir -p                                                                              ${THEME_DIR}/metacity-1
  cp -r ${SRC_DIR}/main/metacity-1/metacity-theme${color}.xml                           ${THEME_DIR}/metacity-1/metacity-theme-1.xml
  cp -r ${SRC_DIR}/main/metacity-1/metacity-theme-3.xml                                 ${THEME_DIR}/metacity-1
  cp -r ${SRC_DIR}/assets/metacity-1/assets/*.png                                       ${THEME_DIR}/metacity-1
  cp -r ${SRC_DIR}/assets/metacity-1/thumbnail${color}.png                              ${THEME_DIR}/metacity-1/thumbnail.png
  cd ${THEME_DIR}/metacity-1 && ln -s metacity-theme-1.xml metacity-theme-2.xml

  mkdir -p                                                                              ${THEME_DIR}/xfwm4
  cp -r ${SRC_DIR}/assets/xfwm4/assets${color}/*.png                                    ${THEME_DIR}/xfwm4
  cp -r ${SRC_DIR}/main/xfwm4/themerc${color}                                           ${THEME_DIR}/xfwm4/themerc

  mkdir -p                                                                              ${THEME_DIR}/cinnamon
  cp -r ${SRC_DIR}/main/cinnamon/cinnamon${color}${opacity}.css                         ${THEME_DIR}/cinnamon/cinnamon.css
  cp -r ${SRC_DIR}/assets/cinnamon/common-assets                                        ${THEME_DIR}/cinnamon/assets
  cp -r ${SRC_DIR}/assets/cinnamon/assets${color}/*.svg                                 ${THEME_DIR}/cinnamon/assets
  cp -r ${SRC_DIR}/assets/cinnamon/thumbnails/thumbnail${color}.png                     ${THEME_DIR}/cinnamon/thumbnail.png

  mkdir -p                                                                              ${THEME_DIR}/plank
  cp -r ${SRC_DIR}/other/plank/theme${color}/*.theme                                    ${THEME_DIR}/plank
}

install_theme() {
  for color in "${colors[@]-${COLOR_VARIANTS[@]}}"; do
    for opacity in "${opacities[@]-${OPACITY_VARIANTS[@]}}"; do
       install "${dest:-${DEST_DIR}}" "${name:-${THEME_NAME}}" "${color}" "${opacity}"
    done
  done

  if [[ -x /usr/bin/notify-send ]]; then
    notify-send "Finished" "Enjoy your ${THEME_NAME} theme!" -i face-smile
  fi
}

# Backup and install files related to GDM theme
GS_THEME_FILE="/usr/share/gnome-shell/gnome-shell-theme.gresource"
SHELL_THEME_FOLDER="/usr/share/gnome-shell/theme"
ETC_THEME_FOLDER="/etc/alternatives"
ETC_THEME_FILE="/etc/alternatives/gdm3.css"
ETC_NEW_THEME_FILE="/etc/alternatives/gdm3-theme.gresource"
UBUNTU_THEME_FILE="/usr/share/gnome-shell/theme/ubuntu.css"
UBUNTU_NEW_THEME_FILE="/usr/share/gnome-shell/theme/gnome-shell.css"
UBUNTU_YARU_THEME_FILE="/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource"

install_gdm() {
  local GDM_THEME_DIR="${1}/${2}${3}"
  local YARU_GDM_THEME_DIR="$SHELL_THEME_FOLDER/Yaru/${2}${3}"

  echo
  prompt -i "Installing ${2}${3} gdm theme..."

  if [[ -f "$GS_THEME_FILE" ]] && command -v glib-compile-resources >/dev/null ; then
    prompt -i "Installing '$GS_THEME_FILE'..."
    cp -an "$GS_THEME_FILE" "$GS_THEME_FILE.bak"
    glib-compile-resources \
      --sourcedir="$GDM_THEME_DIR/gnome-shell" \
      --target="$GS_THEME_FILE" \
      "${SRC_DIR}/main/gnome-shell/gnome-shell-theme.gresource.xml"
  fi

  if [[ -f "$UBUNTU_THEME_FILE" && -f "$GS_THEME_FILE.bak" ]]; then
    prompt -i "Installing '$UBUNTU_THEME_FILE'..."
    cp -an "$UBUNTU_THEME_FILE" "$UBUNTU_THEME_FILE.bak"
    cp -af "$GDM_THEME_DIR/gnome-shell/gnome-shell.css" "$UBUNTU_THEME_FILE"
  fi

  if [[ -f "$UBUNTU_NEW_THEME_FILE" && -f "$GS_THEME_FILE.bak" ]]; then
    prompt -i "Installing '$UBUNTU_NEW_THEME_FILE'..."
    cp -an "$UBUNTU_NEW_THEME_FILE" "$UBUNTU_NEW_THEME_FILE.bak"
    cp -af "$GDM_THEME_DIR"/gnome-shell/* "$SHELL_THEME_FOLDER"
  fi

  # > Ubuntu 18.04
  if [[ -f "$ETC_THEME_FILE" && -f "$GS_THEME_FILE.bak" ]]; then
    prompt -i "Installing Ubuntu GDM theme..."
    cp -an "$ETC_THEME_FILE" "$ETC_THEME_FILE.bak"
    [[ -d "$SHELL_THEME_FOLDER/$THEME_NAME" ]] && rm -rf "$SHELL_THEME_FOLDER/$THEME_NAME"
    cp -r "$GDM_THEME_DIR/gnome-shell" "$SHELL_THEME_FOLDER/$THEME_NAME"
    cd "$ETC_THEME_FOLDER"
    [[ -f "$ETC_THEME_FILE.bak" ]] && ln -sf "$SHELL_THEME_FOLDER/$THEME_NAME/gnome-shell.css" gdm3.css
  fi

  # > Ubuntu 20.04
  if [[ -d "$SHELL_THEME_FOLDER/Yaru" && -f "$GS_THEME_FILE.bak" ]]; then
    prompt -i "Installing Ubuntu GDM theme..."
    cp -an "$UBUNTU_YARU_THEME_FILE" "$UBUNTU_YARU_THEME_FILE.bak"
    rm -rf "$UBUNTU_YARU_THEME_FILE"
    rm -rf "$YARU_GDM_THEME_DIR" && mkdir -p "$YARU_GDM_THEME_DIR"

    mkdir -p                                                                              "$YARU_GDM_THEME_DIR"/gnome-shell
    mkdir -p                                                                              "$YARU_GDM_THEME_DIR"/gnome-shell/Yaru
    cp -r "$SRC_DIR"/assets/gnome-shell/icons                                             "$YARU_GDM_THEME_DIR"/gnome-shell
    cp -r "$SRC_DIR"/main/gnome-shell/pad-osd.css                                         "$YARU_GDM_THEME_DIR"/gnome-shell
    cp -r "$SRC_DIR"/main/gnome-shell/gdm3${color}.css                                    "$YARU_GDM_THEME_DIR"/gnome-shell/gdm3.css
    cp -r "$SRC_DIR"/main/gnome-shell/gnome-shell${color}.css                             "$YARU_GDM_THEME_DIR"/gnome-shell/Yaru/gnome-shell.css
    cp -r "$SRC_DIR"/assets/gnome-shell/common-assets                                     "$YARU_GDM_THEME_DIR"/gnome-shell/assets
    cp -r "$SRC_DIR"/assets/gnome-shell/assets${color}/*.svg                              "$YARU_GDM_THEME_DIR"/gnome-shell/assets
    cp -r "$SRC_DIR"/assets/gnome-shell/activities/activities.svg                         "$YARU_GDM_THEME_DIR"/gnome-shell/assets

    cd "$YARU_GDM_THEME_DIR"/gnome-shell
    mv -f assets/no-events.svg no-events.svg
    mv -f assets/process-working.svg process-working.svg
    mv -f assets/no-notifications.svg no-notifications.svg

    glib-compile-resources \
      --sourcedir="$YARU_GDM_THEME_DIR"/gnome-shell \
      --target="$UBUNTU_YARU_THEME_FILE" \
      "$SRC_DIR"/main/gnome-shell/gnome-shell-yaru-theme.gresource.xml

    rm -rf "$YARU_GDM_THEME_DIR"
  fi
}

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -d|--dest)
      dest="${2}"
      if [[ ! -d "${dest}" ]]; then
        prompt -e "Destination directory does not exist. Let's make a new one..."
        mkdir -p ${dest}
      fi
      shift 2
      ;;
    -n|--name)
      name="${2}"
      shift 2
      ;;
    -g|--gdm)
      gdm='true'
      shift 1
      ;;
    -o|--opacity)
      shift
      for opacity in "${@}"; do
        case "${opacity}" in
          standard)
            opacities+=("${OPACITY_VARIANTS[0]}")
            shift
            ;;
          solid)
            opacities+=("${OPACITY_VARIANTS[1]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            prompt -e "ERROR: Unrecognized opacity variant '$1'."
            prompt -i "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -c|--color)
      shift
      for color in "${@}"; do
        case "${color}" in
          light)
            colors+=("${COLOR_VARIANTS[0]}")
            shift
            ;;
          dark)
            colors+=("${COLOR_VARIANTS[1]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            prompt -e "ERROR: Unrecognized color variant '$1'."
            prompt -i "Try '$0 --help' for more information."
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

# Install dependency
if [ ! "$(which glib-compile-resources 2> /dev/null)" ]; then
  prompt -w "\n 'glib2.0' needs to be installed for this shell"
  if has_command apt; then
    sudo apt install libglib2.0-dev-bin
  elif has_command dnf; then
    sudo dnf install -y glib2-devel
  fi
fi

# Parse scss to css
for color in "${COLOR_VARIANTS[@]}"; do
  for opacity in "${OPACITY_VARIANTS[@]}"; do
    sassc $SASSC_OPT src/main/gtk-3.0/gtk${color}${opacity}.{scss,css}
    echo "==> Generating the gtk${color}${opacity}.css..."
    sassc $SASSC_OPT src/main/cinnamon/cinnamon${color}${opacity}.{scss,css}
    echo "==> Generating the cinnamon${color}${opacity}.css..."
    sassc $SASSC_OPT src/main/gnome-shell/gnome-shell${color}${opacity}.{scss,css}
    echo "==> Generating the gnome-shell${color}${opacity}.css..."
  done

  sassc $SASSC_OPT src/main/gnome-shell/gdm3${color}.{scss,css}
  echo "==> Generating the gdm3${color}.css..."
done

sassc $SASSC_OPT src/other/dash-to-dock/stylesheet.{scss,css}
echo "==> Generating dash-to-dock stylesheet.css..."
sassc $SASSC_OPT src/other/dash-to-dock/stylesheet-dark.{scss,css}
echo "==> Generating dash-to-dock stylesheet-dark.css..."

# Install themes
if [[ "${gdm:-}" != 'true' ]]; then
  install_theme
fi

# Install GDM theme
if [[ "${gdm:-}" == 'true' && "$UID" -eq "$ROOT_UID" ]]; then
  install_theme && install_gdm "${dest:-${DEST_DIR}}" "${name:-${THEME_NAME}}" "${color}" "${opacity}"
fi

prompt -s "\n Done!".
