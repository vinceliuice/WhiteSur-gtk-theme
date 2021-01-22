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

THEME_NAME=WhiteSur
COLOR_VARIANTS=('-light' '-dark')
OPACITY_VARIANTS=('' '-solid')
ALT_VARIANTS=('' '-alt')
THEME_VARIANTS=('' '-blue' '-purple' '-pink' '-red' '-orange' '-yellow' '-green' '-grey')
ICON_VARIANTS=('' '-normal' '-gnome' '-ubuntu' '-arch' '-manjaro' '-fedora' '-debian' '-void')
SIDEBAR_SIZE_VARIANTS=('default' '220' '240' '260' '280')
PANEL_OPACITY_VARIANTS=('default' '25' '35' '45' '55' '65' '75' '85')

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
  printf "  %-25s%s\n" "-a, --alt VARIANTS" "Specify theme Window management (max/min/close) button variant(s) [standard|alt|all] (Default: All variants)"
  printf "  %-25s%s\n" "-t, --theme VARIANTS" "Specify primary theme color [blue|purple|pink|red|orange|yellow|green|grey|all] (Default: MacOS blue)"
  printf "  %-25s%s\n" "-p, --panel VARIANTS" "Change the panel transparency [25|35|45|55|65|75|85] (Default: 85%)"
  printf "  %-25s%s\n" "-s, --size VARIANTS" "Change the nautilus sidebar width size [220|240|260|280] (Default: 200)"
  printf "  %-25s%s\n" "-i, --icon VARIANTS" "Change gnome-shell activities icon [standard|normal|gnome|ubuntu|arch|manjaro|fedora|debian|void] (Default: standard)"
  printf "  %-25s%s\n" "-h, --help" "Show this help"
}

install() {
  local dest=${1}
  local name=${2}
  local color=${3}
  local opacity=${4}
  local alt=${5}
  local theme=${6}
  local icon=${7}
  local panel_opacity=${8}
  local sidebar_size=${9}

  [[ ${color} == '-light' ]] && local ELSE_LIGHT=${color}
  [[ ${color} == '-dark' ]] && local ELSE_DARK=${color}

  local THEME_DIR=${1}/${2}${3}${4}${5}${6}

  [[ -d ${THEME_DIR} ]] && rm -rf ${THEME_DIR}

  prompt -i "Installing '${THEME_DIR}'..."

  mkdir -p                                                                              ${THEME_DIR}

  echo "[Desktop Entry]" >>                                                             ${THEME_DIR}/index.theme
  echo "Type=X-GNOME-Metatheme" >>                                                      ${THEME_DIR}/index.theme
  echo "Name=${2}${3}${4}${5}${6}" >>                                                   ${THEME_DIR}/index.theme
  echo "Comment=A MacOS BigSur like Gtk+ theme based on Elegant Design" >>              ${THEME_DIR}/index.theme
  echo "Encoding=UTF-8" >>                                                              ${THEME_DIR}/index.theme
  echo "" >>                                                                            ${THEME_DIR}/index.theme
  echo "[X-GNOME-Metatheme]" >>                                                         ${THEME_DIR}/index.theme
  echo "GtkTheme=${2}${3}${4}${5}${6}" >>                                               ${THEME_DIR}/index.theme
  echo "MetacityTheme=${2}${3}${4}${5}${6}" >>                                          ${THEME_DIR}/index.theme
  echo "IconTheme=${2}${3}" >>                                                          ${THEME_DIR}/index.theme
  echo "CursorTheme=${2}${3}" >>                                                        ${THEME_DIR}/index.theme
  echo "ButtonLayout=close,minimize,maximize:menu" >>                                   ${THEME_DIR}/index.theme

  mkdir -p                                                                              ${THEME_DIR}/gnome-shell
  cp -r ${SRC_DIR}/assets/gnome-shell/icons                                             ${THEME_DIR}/gnome-shell
  cp -r ${SRC_DIR}/main/gnome-shell/pad-osd.css                                         ${THEME_DIR}/gnome-shell
  cp -r ${SRC_DIR}/main/gnome-shell/gnome-shell${color}${opacity}${alt}${theme}.css     ${THEME_DIR}/gnome-shell/gnome-shell.css
  cp -r ${SRC_DIR}/assets/gnome-shell/common-assets                                     ${THEME_DIR}/gnome-shell/assets

  if [[ ${theme} != '-default' ]]; then
    cp -r ${SRC_DIR}/assets/gnome-shell/common-assets${theme}/*.svg                     ${THEME_DIR}/gnome-shell/assets
  fi

  cp -r ${SRC_DIR}/assets/gnome-shell/assets${color}/*.svg                              ${THEME_DIR}/gnome-shell/assets
  cp -r ${SRC_DIR}/assets/gnome-shell/activities/activities${icon}.svg                  ${THEME_DIR}/gnome-shell/assets/activities.svg

  cd "${THEME_DIR}/gnome-shell"
  mv -f assets/no-events.svg no-events.svg
  mv -f assets/process-working.svg process-working.svg
  mv -f assets/no-notifications.svg no-notifications.svg

  if [[ ${alt} == '-alt' || ${opacity} == '-solid' ]] &&  [[ ${color} == '-light' ]]; then
    cp -r ${SRC_DIR}/assets/gnome-shell/activities-black/activities${icon}.svg          ${THEME_DIR}/gnome-shell/assets/activities.svg
    cp -r ${SRC_DIR}/assets/gnome-shell/activities/activities${icon}.svg                ${THEME_DIR}/gnome-shell/assets/activities-white.svg
  fi

  mkdir -p                                                                              ${THEME_DIR}/gtk-2.0
  cp -r ${SRC_DIR}/main/gtk-2.0/gtkrc${color}${theme}                                   ${THEME_DIR}/gtk-2.0/gtkrc
  cp -r ${SRC_DIR}/main/gtk-2.0/menubar-toolbar${color}.rc                              ${THEME_DIR}/gtk-2.0/menubar-toolbar.rc
  cp -r ${SRC_DIR}/main/gtk-2.0/common/*.rc                                             ${THEME_DIR}/gtk-2.0
  cp -r ${SRC_DIR}/assets/gtk-2.0/assets${color}                                        ${THEME_DIR}/gtk-2.0/assets

  if [[ ${theme} != '-default' ]]; then
    cp -r ${SRC_DIR}/assets/gtk-2.0/assets${color}${theme}/*.png                        ${THEME_DIR}/gtk-2.0/assets
  fi

  mkdir -p                                                                              ${THEME_DIR}/gtk-3.0
  cp -r ${SRC_DIR}/assets/gtk-3.0/common-assets/assets                                  ${THEME_DIR}/gtk-3.0

  if [[ ${theme} != '-default' ]]; then
    cp -r ${SRC_DIR}/assets/gtk-3.0/common-assets/assets${theme}/*.png                  ${THEME_DIR}/gtk-3.0/assets
  fi

  cp -r ${SRC_DIR}/assets/gtk-3.0/common-assets/sidebar-assets/*.png                    ${THEME_DIR}/gtk-3.0/assets
  cp -r ${SRC_DIR}/assets/gtk-3.0/windows-assets/titlebutton${alt}                      ${THEME_DIR}/gtk-3.0/windows-assets
  cp -r ${SRC_DIR}/assets/gtk-3.0/thumbnails/thumbnail${color}${theme}.png              ${THEME_DIR}/gtk-3.0/thumbnail.png
  cp -r ${SRC_DIR}/main/gtk-3.0/gtk-dark${opacity}${theme}.css                          ${THEME_DIR}/gtk-3.0/gtk-dark.css

  if [[ ${color} == '-light' ]]; then
    cp -r ${SRC_DIR}/main/gtk-3.0/gtk-light${opacity}${theme}.css                       ${THEME_DIR}/gtk-3.0/gtk.css
  else
    cp -r ${SRC_DIR}/main/gtk-3.0/gtk-dark${opacity}${theme}.css                        ${THEME_DIR}/gtk-3.0/gtk.css
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
  cp -r ${SRC_DIR}/main/cinnamon/cinnamon${color}${opacity}${theme}.css                 ${THEME_DIR}/cinnamon/cinnamon.css
  cp -r ${SRC_DIR}/assets/cinnamon/common-assets                                        ${THEME_DIR}/cinnamon/assets

  if [[ ${theme} != '-default' ]]; then
    cp -r ${SRC_DIR}/assets/cinnamon/common-assets${theme}/*.svg                        ${THEME_DIR}/cinnamon/assets
  fi

  cp -r ${SRC_DIR}/assets/cinnamon/assets${color}/*.svg                                 ${THEME_DIR}/cinnamon/assets
  cp -r ${SRC_DIR}/assets/cinnamon/thumbnails/thumbnail${color}${theme}.png             ${THEME_DIR}/cinnamon/thumbnail.png

  mkdir -p                                                                              ${THEME_DIR}/plank
  cp -r ${SRC_DIR}/other/plank/theme${color}/*.theme                                    ${THEME_DIR}/plank
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
    -r|--remove)
      remove='true'
      shift 1
      ;;
    -dialog|--dialog)
      dialogs='true'
      shift 1
      ;;
    -a|--alt)
      shift
      for alt in "${@}"; do
        case "${alt}" in
          standard)
            alts+=("${ALT_VARIANTS[0]}")
            shift
            ;;
          alt)
            alts+=("${ALT_VARIANTS[1]}")
            shift
            ;;
          all)
            alts+=("${ALT_VARIANTS[@]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            prompt -e "ERROR: Unrecognized window button variant '$1'."
            prompt -i "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
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
    -i|--icon)
      shift
      for icon in "${@}"; do
        case "${icon}" in
          standard)
            icons+=("${ICON_VARIANTS[0]}")
            shift
            ;;
          normal)
            icons+=("${ICON_VARIANTS[1]}")
            shift
            ;;
          gnome)
            icons+=("${ICON_VARIANTS[2]}")
            shift
            ;;
          ubuntu)
            icons+=("${ICON_VARIANTS[3]}")
            shift
            ;;
          arch)
            icons+=("${ICON_VARIANTS[4]}")
            shift
            ;;
          manjaro)
            icons+=("${ICON_VARIANTS[5]}")
            shift
            ;;
          fedora)
            icons+=("${ICON_VARIANTS[6]}")
            shift
            ;;
          debian)
            icons+=("${ICON_VARIANTS[7]}")
            shift
            ;;
          void)
            icons+=("${ICON_VARIANTS[8]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            prompt -e "ERROR: Unrecognized icon variant '$1'."
            prompt -i "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -t|--theme)
      shift
      for theme in "${@}"; do
        case "${theme}" in
          default)
            themes+=("${THEME_VARIANTS[0]}")
            shift
            ;;
          blue)
            themes+=("${THEME_VARIANTS[1]}")
            shift
            ;;
          purple)
            themes+=("${THEME_VARIANTS[2]}")
            shift
            ;;
          pink)
            themes+=("${THEME_VARIANTS[3]}")
            shift
            ;;
          red)
            themes+=("${THEME_VARIANTS[4]}")
            shift
            ;;
          orange)
            themes+=("${THEME_VARIANTS[5]}")
            shift
            ;;
          yellow)
            themes+=("${THEME_VARIANTS[6]}")
            shift
            ;;
          green)
            themes+=("${THEME_VARIANTS[7]}")
            shift
            ;;
          grey)
            themes+=("${THEME_VARIANTS[8]}")
            shift
            ;;
          all)
            themes+=("${THEME_VARIANTS[@]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            prompt -e "ERROR: Unrecognized theme variant '$1'."
            prompt -i "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -s|--size)
      size='true'
      shift
      for sidebar_size in "${@}"; do
        case "${sidebar_size}" in
          default)
            sidebar_sizes+=("${SIDEBAR_SIZE_VARIANTS[0]}")
            shift
            ;;
          220)
            sidebar_sizes+=("${SIDEBAR_SIZE_VARIANTS[1]}")
            shift
            ;;
          240)
            sidebar_sizes+=("${SIDEBAR_SIZE_VARIANTS[2]}")
            shift
            ;;
          260)
            sidebar_sizes+=("${SIDEBAR_SIZE_VARIANTS[3]}")
            shift
            ;;
          280)
            sidebar_sizes+=("${SIDEBAR_SIZE_VARIANTS[4]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            customize_theme_dialogs
            ;;
        esac
      done
      ;;
    -p|--panel)
      panel='true'
      pdialog='true'
      shift
      for panel_opacity in "${@}"; do
        case "${panel_opacity}" in
          default)
            pdialog='false'
            panel_opacities+=("${PANEL_OPACITY_VARIANTS[0]}")
            shift
            ;;
          25)
            pdialog='false'
            panel_opacities+=("${PANEL_OPACITY_VARIANTS[1]}")
            shift
            ;;
          35)
            pdialog='false'
            panel_opacities+=("${PANEL_OPACITY_VARIANTS[2]}")
            shift
            ;;
          45)
            pdialog='false'
            panel_opacities+=("${PANEL_OPACITY_VARIANTS[3]}")
            shift
            ;;
          55)
            pdialog='false'
            panel_opacities+=("${PANEL_OPACITY_VARIANTS[4]}")
            shift
            ;;
          65)
            pdialog='false'
            panel_opacities+=("${PANEL_OPACITY_VARIANTS[5]}")
            shift
            ;;
          75)
            pdialog='false'
            panel_opacities+=("${PANEL_OPACITY_VARIANTS[6]}")
            shift
            ;;
          85)
            pdialog='false'
            panel_opacities+=("${PANEL_OPACITY_VARIANTS[7]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            customize_theme_dialogs
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

install_theme() {
  for color in "${colors[@]-${COLOR_VARIANTS[@]}}"; do
    for opacity in "${opacities[@]-${OPACITY_VARIANTS[@]}}"; do
      for alt in "${alts[@]-${ALT_VARIANTS[0]}}"; do
        for theme in "${themes[@]-${THEME_VARIANTS[0]}}"; do
          for icon in "${icons[@]-${ICON_VARIANTS[0]}}"; do
            for panel_opacity in "${panel_opacities[@]-${PANEL_OPACITY_VARIANTS[0]}}"; do
              for sidebar_size in "${sidebar_sizes[@]-${SIDEBAR_SIZE_VARIANTS[0]}}"; do
                install "${dest:-${DEST_DIR}}" "${name:-${THEME_NAME}}" "${color}" "${opacity}" "${alt}" "${theme}" "${icon}" "${panel_opacity}" "${sidebar_size}"
              done
            done
          done
        done
      done
    done
  done

  if [[ -x /usr/bin/notify-send ]]; then
    notify-send "Finished" "Enjoy your ${THEME_NAME} "${theme}" theme!" -i face-smile
  fi
}

install_customize_theme() {
  for panel_opacity in "${panel_opacities[@]-${PANEL_OPACITY_VARIANTS[0]}}"; do
    for sidebar_size in "${sidebar_sizes[@]-${SIDEBAR_SIZE_VARIANTS[0]}}"; do
      customize_theme "${panel_opacity}" "${sidebar_size}"
    done
  done
}

remove_theme() {
  for color in "${colors[@]-${COLOR_VARIANTS[@]}}"; do
    for opacity in "${opacities[@]-${OPACITY_VARIANTS[@]}}"; do
      for alt in "${alts[@]-${ALT_VARIANTS[@]}}"; do
        for theme in "${themes[@]-${THEME_VARIANTS[@]}}"; do
          [[ -d "${DEST_DIR}/${THEME_NAME}${color}${opacity}${alt}${theme}" ]] && rm -rf "${DEST_DIR}/${THEME_NAME}${color}${opacity}${alt}${theme}"
        done
      done
    done
  done
}

customize_theme() {
  # Change gnome-shell panel transparency
  if [[ "${panel:-}" == 'true' && "${panel_opacity:-}" != 'default' ]]; then
    change_transparency
  fi

  # Change nautilus sibarbar size
  if [[ "${size:-}" == 'true' && "${sidebar_size:-}" != 'default' ]]; then
    change_size
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
POP_OS_THEME_FILE="/usr/share/gnome-shell/theme/Pop/gnome-shell-theme.gresource"

install_gdm() {
  local GDM_THEME_DIR="${1}/${2}${3}${4}${5}"
  local YARU_GDM_THEME_DIR="$SHELL_THEME_FOLDER/Yaru/${2}${3}${4}${5}"
  local POP_GDM_THEME_DIR="$SHELL_THEME_FOLDER/Pop/${2}${3}${4}${5}"

  echo
  prompt -i "Installing ${2}${3}${4}${5} gdm theme..."

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

  # > Pop_OS 20.04
  if [[ -d "$SHELL_THEME_FOLDER/Pop" && -f "$GS_THEME_FILE.bak" ]]; then
    prompt -i "Installing Pop_OS GDM theme..."
    cp -an "$POP_OS_THEME_FILE" "$POP_OS_THEME_FILE.bak"
    rm -rf "$POP_OS_THEME_FILE"
    rm -rf "$POP_GDM_THEME_DIR" && mkdir -p "$POP_GDM_THEME_DIR"

    mkdir -p                                                                              "$POP_GDM_THEME_DIR"/gnome-shell
    cp -r "$SRC_DIR"/assets/gnome-shell/icons                                             "$POP_GDM_THEME_DIR"/gnome-shell
    cp -r "$SRC_DIR"/main/gnome-shell/pad-osd.css                                         "$POP_GDM_THEME_DIR"/gnome-shell
    cp -r "$SRC_DIR"/main/gnome-shell/gdm3${color}.css                                    "$POP_GDM_THEME_DIR"/gnome-shell/gdm3.css
    cp -r "$SRC_DIR"/main/gnome-shell/gnome-shell${color}.css                             "$POP_GDM_THEME_DIR"/gnome-shell/gnome-shell.css
    cp -r "$SRC_DIR"/assets/gnome-shell/common-assets                                     "$POP_GDM_THEME_DIR"/gnome-shell/assets
    cp -r "$SRC_DIR"/assets/gnome-shell/assets${color}/*.svg                              "$POP_GDM_THEME_DIR"/gnome-shell/assets
    cp -r "$SRC_DIR"/assets/gnome-shell/activities/activities.svg                         "$POP_GDM_THEME_DIR"/gnome-shell/assets

    cd "$POP_GDM_THEME_DIR"/gnome-shell
    mv -f assets/no-events.svg no-events.svg
    mv -f assets/process-working.svg process-working.svg
    mv -f assets/no-notifications.svg no-notifications.svg

    glib-compile-resources \
      --sourcedir="$POP_GDM_THEME_DIR"/gnome-shell \
      --target="$POP_OS_THEME_FILE" \
      "$SRC_DIR"/main/gnome-shell/gnome-shell-pop-theme.gresource.xml

    rm -rf "$POP_GDM_THEME_DIR"
  fi
}

revert_gdm() {
  if [[ -f "$GS_THEME_FILE.bak" ]]; then
    prompt -w "Reverting '$GS_THEME_FILE'..."
    rm -rf "$GS_THEME_FILE"
    mv "$GS_THEME_FILE.bak" "$GS_THEME_FILE"
  fi

  if [[ -f "$UBUNTU_THEME_FILE.bak" ]]; then
    prompt -w "Reverting '$UBUNTU_THEME_FILE'..."
    rm -rf "$UBUNTU_THEME_FILE"
    mv "$UBUNTU_THEME_FILE.bak" "$UBUNTU_THEME_FILE"
  fi

  if [[ -f "$UBUNTU_NEW_THEME_FILE.bak" ]]; then
    prompt -w "Reverting '$UBUNTU_NEW_THEME_FILE'..."
    rm -rf "$UBUNTU_NEW_THEME_FILE" "$SHELL_THEME_FOLDER"/{assets,no-events.svg,process-working.svg,no-notifications.svg}
    mv "$UBUNTU_NEW_THEME_FILE.bak" "$UBUNTU_NEW_THEME_FILE"
  fi

  # > Ubuntu 18.04
  if [[ -f "$ETC_THEME_FILE.bak" ]]; then

    prompt -w "reverting Ubuntu GDM theme..."

    rm -rf "$ETC_THEME_FILE"
    mv "$ETC_THEME_FILE.bak" "$ETC_THEME_FILE"
    [[ -d $SHELL_THEME_FOLDER/$THEME_NAME ]] && rm -rf $SHELL_THEME_FOLDER/$THEME_NAME
  fi

  # > Ubuntu 20.04
  if [[ -f "$UBUNTU_YARU_THEME_FILE.bak" ]]; then
    prompt -w "reverting Ubuntu GDM theme..."
    rm -rf "$UBUNTU_YARU_THEME_FILE"
    mv "$UBUNTU_YARU_THEME_FILE.bak" "$UBUNTU_YARU_THEME_FILE"
  fi

  # > Pop_OS 20.04
  if [[ -f "$POP_OS_THEME_FILE.bak" ]]; then
    prompt -w "reverting Pop_OS GDM theme..."
    rm -rf "$POP_OS_THEME_FILE"
    mv "$POP_OS_THEME_FILE.bak" "$POP_OS_THEME_FILE"
  fi
}

install_dialog() {
  if [ ! "$(which dialog 2> /dev/null)" ]; then
    prompt -w "\n 'dialog' needs to be installed for this shell"
    if has_command zypper; then
      sudo zypper in dialog
    elif has_command apt-get; then
      sudo apt-get install dialog
    elif has_command dnf; then
      sudo dnf install -y dialog
    elif has_command yum; then
      sudo yum install dialog
    elif has_command pacman; then
      sudo pacman -S --noconfirm dialog
    fi
  fi
}

customize_theme_dialogs() {
  if [[ -x /usr/bin/dialog ]]; then
    tui=$(dialog --backtitle "${THEME_NAME} gtk theme installer" \
    --radiolist "Choose your panel background opacity
                (default is 0.16, value more smaller panel more transparency!):" 20 50 10 \
      0 "default" on  \
      1 "0.25" off  \
      2 "0.35" off \
      3 "0.45" off \
      4 "0.55" off \
      5 "0.65" off \
      6 "0.75" off \
      7 "0.85" off --output-fd 1 )
      case "$tui" in
        0) panel_opacity="default" ;;
        1) panel_opacity="25" ;;
        2) panel_opacity="35" ;;
        3) panel_opacity="45" ;;
        4) panel_opacity="55" ;;
        5) panel_opacity="65" ;;
        6) panel_opacity="75" ;;
        7) panel_opacity="85" ;;
        *) operation_canceled ;;
      esac

    tui=$(dialog --backtitle "${THEME_NAME} gtk theme installer" \
    --radiolist "Choose your nautilus sidebar size (default is 200px width):" 15 40 5 \
      0 "default" on \
      1 "220px" off \
      2 "240px" off \
      3 "260px" off \
      4 "280px" off --output-fd 1 )
      case "$tui" in
        0) sidebar_size="default" ;;
        1) sidebar_size="220" ;;
        2) sidebar_size="240" ;;
        3) sidebar_size="260" ;;
        4) sidebar_size="280" ;;
        *) operation_canceled ;;
      esac
  fi
}

run_customize_theme_dialogs() {
  install_dialog && customize_theme_dialogs && change_transparency && change_size && parse_sass
}

parse_sass() {
  cd ${REPO_DIR} && ./parse-sass.sh
}

change_size() {
  if [[ "${sidebar_size:-}" != 'default' ]]; then
    cd ${SRC_DIR}/sass/gtk
    sed -i.bak "/\$nautilus_sidebar_size/s/sidebar_size_default/sidebar_size_${sidebar_size}/" _applications.scss
    prompt -w "Change nautilus sidebar size ..."
  fi
}

change_transparency() {
  if [[ "${panel_opacity:-}" != 'default' ]]; then
    cd ${SRC_DIR}/sass
    sed -i.bak "/\$panel_opacity/s/0.16/0.${panel_opacity}/" _variables.scss
    prompt -w "Change panel transparency ..."
  fi
}

restore_files() {
  if [[ -f ${SRC_DIR}/sass/gtk/_applications.scss.bak ]]; then
    local restore_file='true'
    cd ${SRC_DIR}/sass/gtk
    rm -rf _applications.scss
    mv -f _applications.scss.bak _applications.scss
    prompt -w "Restore _applications.scss file ..."
  fi

  if [[ -f ${SRC_DIR}/sass/_variables.scss.bak ]]; then
    local restore_file='true'
    cd ${SRC_DIR}/sass
    rm -rf _variables.scss
    mv -f _variables.scss.bak _variables.scss
    prompt -w "Restore _variables.scss file ..."
  fi

  if [[ "${restore_file:-}" == 'true' ]]; then
    parse_sass
  fi
}

# Install dependency
if [ ! "$(which glib-compile-resources 2> /dev/null)" ]; then
  prompt -w "\n 'glib2.0' needs to be installed for this shell"
  if has_command apt; then
    sudo apt install libglib2.0-dev-bin
  elif has_command dnf; then
    sudo dnf install -y glib2-devel
  fi
fi

# Install themes
if [[ "${remove:-}" != 'true' && "${gdm:-}" != 'true' ]]; then
  if [[ "${dialogs:-}" == 'true' ]]; then
    run_customize_theme_dialogs
  fi

  if [[ "${size:-}" != 'true' && "${panel:-}" != 'true' ]]; then
    install_theme
  else
    install_customize_theme && parse_sass && install_theme "${panel_opacity}" "${sidebar_size}"
  fi
fi

# Install GDM theme
if [[ "${gdm:-}" == 'true' && "${remove:-}" != 'true' && "$UID" -eq "$ROOT_UID" ]]; then
  install_theme && install_gdm "${dest:-${DEST_DIR}}" "${name:-${THEME_NAME}}" "${color}" "${opacity}" "${theme}"
fi

# Remove themes
if [[ "${gdm:-}" != 'true' && "${remove:-}" == 'true' ]]; then
  remove_theme

  echo
  prompt -i $THEME_NAME themes all removed!.
fi

# Remove GDM theme (only)
if [[ "${gdm:-}" == 'true' && "${remove:-}" == 'true' && "$UID" -eq "$ROOT_UID" ]]; then
  revert_gdm
fi

# Restore files
restore_files

prompt -s "\n Done!".
