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
ICON_VARIANTS=('' '-normal' '-gnome' '-ubuntu' '-arch' '-manjaro' '-fedora' '-debian' '-void')
THEME_COLOR_VARIANTS=('default' 'blue' 'purple' 'pink' 'red' 'orange' 'yellow' 'green' 'grey')
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
  printf "  %-25s%s\n" "-a, --alt VARIANTS" "Specify theme titlebutton variant(s) [standard|alt] (Default: All variants)"
  printf "  %-25s%s\n" "-t, --theme VARIANTS" "Change the theme color [blue|purple|pink|red|orange|yellow|green|grey] (Default: MacOS blue)"
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
  local icon=${6}
  local panel_opacity=${7}
  local sidebar_size=${8}
  local theme_color=${9}

  [[ ${color} == '-light' ]] && local ELSE_LIGHT=${color}
  [[ ${color} == '-dark' ]] && local ELSE_DARK=${color}

  local THEME_DIR=${1}/${2}${3}${4}${5}

  [[ -d ${THEME_DIR} ]] && rm -rf ${THEME_DIR}

  prompt -i "Installing '${THEME_DIR}'..."

  mkdir -p                                                                              ${THEME_DIR}
  cp -r ${REPO_DIR}/COPYING                                                             ${THEME_DIR}

  echo "[Desktop Entry]" >>                                                             ${THEME_DIR}/index.theme
  echo "Type=X-GNOME-Metatheme" >>                                                      ${THEME_DIR}/index.theme
  echo "Name=${name}${color}${opacity}" >>                                              ${THEME_DIR}/index.theme
  echo "Comment=A Stylish Gtk+ theme based on Elegant Design" >>                        ${THEME_DIR}/index.theme
  echo "Encoding=UTF-8" >>                                                              ${THEME_DIR}/index.theme
  echo "" >>                                                                            ${THEME_DIR}/index.theme
  echo "[X-GNOME-Metatheme]" >>                                                         ${THEME_DIR}/index.theme
  echo "GtkTheme=${name}${color}${opacity}" >>                                          ${THEME_DIR}/index.theme
  echo "MetacityTheme=${name}${color}${opacity}" >>                                     ${THEME_DIR}/index.theme
  echo "IconTheme=McMojave-circle" >>                                                   ${THEME_DIR}/index.theme
  echo "CursorTheme=McMojave-circle" >>                                                 ${THEME_DIR}/index.theme
  echo "ButtonLayout=close,minimize,maximize:menu" >>                                   ${THEME_DIR}/index.theme

  mkdir -p                                                                              ${THEME_DIR}/gnome-shell
  cp -r ${SRC_DIR}/assets/gnome-shell/icons                                             ${THEME_DIR}/gnome-shell
  cp -r ${SRC_DIR}/main/gnome-shell/pad-osd.css                                         ${THEME_DIR}/gnome-shell
  cp -r ${SRC_DIR}/main/gnome-shell/gnome-shell${color}${opacity}${alt}.css             ${THEME_DIR}/gnome-shell/gnome-shell.css
  cp -r ${SRC_DIR}/assets/gnome-shell/common-assets                                     ${THEME_DIR}/gnome-shell/assets
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
  cp -r ${SRC_DIR}/main/gtk-2.0/gtkrc${color}                                           ${THEME_DIR}/gtk-2.0/gtkrc
  cp -r ${SRC_DIR}/main/gtk-2.0/menubar-toolbar${color}.rc                              ${THEME_DIR}/gtk-2.0/menubar-toolbar.rc
  cp -r ${SRC_DIR}/main/gtk-2.0/common/*.rc                                             ${THEME_DIR}/gtk-2.0
  cp -r ${SRC_DIR}/assets/gtk-2.0/assets${color}                                        ${THEME_DIR}/gtk-2.0/assets

  mkdir -p                                                                              ${THEME_DIR}/gtk-3.0
  cp -r ${SRC_DIR}/assets/gtk-3.0/common-assets/assets                                  ${THEME_DIR}/gtk-3.0
  cp -r ${SRC_DIR}/assets/gtk-3.0/common-assets/sidebar-assets/*.png                    ${THEME_DIR}/gtk-3.0/assets
  cp -r ${SRC_DIR}/assets/gtk-3.0/windows-assets/titlebutton${alt}                      ${THEME_DIR}/gtk-3.0/windows-assets
  cp -r ${SRC_DIR}/assets/gtk-3.0/thumbnail${color}.png                                 ${THEME_DIR}/gtk-3.0/thumbnail.png
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
  cp -r ${SRC_DIR}/assets/cinnamon/thumbnail${color}.png                                ${THEME_DIR}/cinnamon/thumbnail.png

  mkdir -p                                                                              ${THEME_DIR}/plank
  cp -r ${SRC_DIR}/other/plank/theme${color}/*.theme                                    ${THEME_DIR}/plank
}

install_theme() {
  for color in "${colors[@]-${COLOR_VARIANTS[@]}}"; do
    for opacity in "${opacities[@]-${OPACITY_VARIANTS[@]}}"; do
      for alt in "${alts[@]-${ALT_VARIANTS[@]}}"; do
        for icon in "${icons[@]-${ICON_VARIANTS[0]}}"; do
          for panel_opacity in "${panel_opacities[@]-${PANEL_OPACITY_VARIANTS[0]}}"; do
            for sidebar_size in "${sidebar_sizes[@]-${SIDEBAR_SIZE_VARIANTS[0]}}"; do
              for theme_color in "${theme_colors[@]-${THEME_COLOR_VARIANTS[0]}}"; do
                install "${dest:-${DEST_DIR}}" "${name:-${THEME_NAME}}" "${color}" "${opacity}" "${alt}" "${icon}" "${panel_opacity}" "${sidebar_size}" "${theme_color}"
              done
            done
          done
        done
      done
    done
  done

  if [[ -x /usr/bin/notify-send ]]; then
    notify-send "Finished" "Enjoy your ${THEME_NAME} "${theme_color}" theme!" -i face-smile
  fi
}

install_customize_theme() {
  for panel_opacity in "${panel_opacities[@]-${PANEL_OPACITY_VARIANTS[0]}}"; do
    for sidebar_size in "${sidebar_sizes[@]-${SIDEBAR_SIZE_VARIANTS[0]}}"; do
      for theme_color in "${theme_colors[@]-${THEME_COLOR_VARIANTS[0]}}"; do
        customize_theme "${panel_opacity}" "${sidebar_size}" "${theme_color}"
      done
    done
  done
}

remove_theme() {
  for color in "${colors[@]-${COLOR_VARIANTS[@]}}"; do
    for opacity in "${opacities[@]-${OPACITY_VARIANTS[@]}}"; do
      for alt in "${alts[@]-${ALT_VARIANTS[@]}}"; do
        [[ -d "${DEST_DIR}/${THEME_NAME}${color}${opacity}${alt}" ]] && rm -rf "${DEST_DIR}/${THEME_NAME}${color}${opacity}${alt}"
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

  # Change accent color
  if [[ "${theme:-}" == 'true' && "${theme_color:-}" != 'default' ]]; then
    change_theme_color
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
UBUNTU_JSON_FILE="/usr/share/gnome-shell/modes/ubuntu.json"
YURA_JSON_FILE="/usr/share/gnome-shell/modes/yaru.json"
UBUNTU_MODES_FOLDER="/usr/share/gnome-shell/modes"

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
    # [[ -d "$UBUNTU_MODES_FOLDER" ]] && cp -an "$UBUNTU_MODES_FOLDER" "$UBUNTU_MODES_FOLDER"-bak
    # [[ -f "$UBUNTU_JSON_FILE" ]] && sed -i "s|Yaru/gnome-shell.css|gnome-shell.css|" "$UBUNTU_JSON_FILE"
    # [[ -f "$YURA_JSON_FILE" ]] && sed -i "s|Yaru/gnome-shell.css|gnome-shell.css|" "$YURA_JSON_FILE"
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
    [[ -d "$UBUNTU_MODES_FOLDER"-bak ]] && rm -rf "$UBUNTU_MODES_FOLDER" && mv "$UBUNTU_MODES_FOLDER"-bak "$UBUNTU_MODES_FOLDER"
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
    --radiolist "Choose your theme color (default is Mac Blue):" 20 50 10 \
      0 "default" on \
      1 "Blue"   off \
      2 "Purple" off \
      3 "Pink"   off \
      4 "Red"    off \
      5 "Orange" off \
      6 "Yellow" off \
      7 "Green"  off \
      8 "Grey"   off --output-fd 1 )
      case "$tui" in
        0) theme_color="default" ;;
        1) theme_color="blue"   ;;
        2) theme_color="purple" ;;
        3) theme_color="pink"   ;;
        4) theme_color="red"    ;;
        5) theme_color="orange" ;;
        6) theme_color="yellow" ;;
        7) theme_color="green"  ;;
        8) theme_color="grey"   ;;
        *) operation_canceled ;;
      esac

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
  install_dialog && customize_theme_dialogs && change_theme_color && change_transparency && change_size && parse_sass
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

change_theme_color() {
  if [[ -x /usr/bin/notify-send ]]; then
    notify-send "Notice" "It will take a few minutes to regenerate the assets files, please be patient!" -i face-wink
  fi

  cd ${SRC_DIR}/sass
  sed -i.bak "/\$selected_bg_color/s/theme_color_default/theme_color_${theme_color}/" _colors.scss

  if [[ ${theme_color} == 'blue' ]]; then
    local accent="#2E7CF7"
  elif [[ ${theme_color} == 'purple' ]]; then
    local accent="#9A57A3"
  elif [[ ${theme_color} == 'pink' ]]; then
    local accent="#E55E9C"
  elif [[ ${theme_color} == 'red' ]]; then
    local accent="#ED5F5D"
  elif [[ ${theme_color} == 'orange' ]]; then
    local accent="#E9873A"
  elif [[ ${theme_color} == 'yellow' ]]; then
    local accent="#F3BA4B"
  elif [[ ${theme_color} == 'green' ]]; then
    local accent="#79B757"
  elif [[ ${theme_color} == 'grey' ]]; then
    local accent="#8C8C8C"
  elif [[ ${theme_color} == 'default' ]]; then
    local accent="#0860F2"
  else
    prompt -i "\n Run ./install.sh -h for help or install dialog"
    prompt -i "\n Run ./install.sh again!"
    exit 0
  fi

  if [[ "${theme_color:-}" != 'default' ]]; then
    cd ${SRC_DIR}/assets/gtk-3.0
    mv -f thumbnail-dark.png thumbnail-dark.png.bak
    mv -f thumbnail-light.png thumbnail-light.png.bak
    sed -i.bak "s/#0860f2/${accent}/g" thumbnail.svg
    ./render-thumbnails.sh

    cd ${SRC_DIR}/assets/gtk-3.0/common-assets
    cp -an assets assets-bak
    sed -i.bak "s/#0860f2/${accent}/g" assets.svg
    ./render-assets.sh

    cd ${SRC_DIR}/assets/gnome-shell/common-assets
    sed -i.bak "s/#0860f2/${accent}/g" {checkbox.svg,more-results.svg,toggle-on.svg}

    cd ${SRC_DIR}/main/gtk-2.0
    sed -i.bak "s/#0860f2/${accent}/g" {gtkrc-dark,gtkrc-light}

    cd ${SRC_DIR}/assets/gtk-2.0
    cp -an assets-dark assets-dark-bak
    cp -an assets-light assets-light-bak
    sed -i.bak "s/#0860f2/${accent}/g" {assets-dark.svg,assets-light.svg}
    ./render-assets.sh

    cd ${SRC_DIR}/assets/cinnamon
    mv -f thumbnail-dark.png thumbnail-dark.png.bak
    mv -f thumbnail-light.png thumbnail-light.png.bak
    sed -i.bak "s/#0860f2/${accent}/g" thumbnail.svg
    ./render-thumbnails.sh

    cd ${SRC_DIR}/assets/cinnamon/common-assets
    sed -i.bak "s/#0860f2/${accent}/g" {checkbox.svg,radiobutton.svg,menu-hover.svg,add-workspace-active.svg,corner-ripple.svg,toggle-on.svg}

    prompt -w "Change theme color ..."
  fi
}

restore_assets_files() {
  echo "  restore gtk-3.0 thumbnail files"
  mv -f "$SRC_DIR/assets/gtk-3.0/thumbnail.svg.bak" "$SRC_DIR/assets/gtk-3.0/thumbnail.svg"
  mv -f "$SRC_DIR/assets/gtk-3.0/thumbnail-dark.png.bak" "$SRC_DIR/assets/gtk-3.0/thumbnail-dark.png"
  mv -f "$SRC_DIR/assets/gtk-3.0/thumbnail-light.png.bak" "$SRC_DIR/assets/gtk-3.0/thumbnail-light.png"

  echo "  restore gtk-3.0 assets files"
  mv -f "$SRC_DIR/assets/gtk-3.0/common-assets/assets.svg.bak" "$SRC_DIR/assets/gtk-3.0/common-assets/assets.svg"

  if [[ -d "$SRC_DIR/assets/gtk-3.0/common-assets/assets-bak" ]]; then
    rm -rf "$SRC_DIR/assets/gtk-3.0/common-assets/assets"
    mv -f "$SRC_DIR/assets/gtk-3.0/common-assets/assets-bak" "$SRC_DIR/assets/gtk-3.0/common-assets/assets"
  fi

  echo "...restore gnome-shell assets files"
  cd "$SRC_DIR/assets/gnome-shell/common-assets"
  mv -f checkbox.svg.bak checkbox.svg
  mv -f more-results.svg.bak more-results.svg
  mv -f toggle-on.svg.bak toggle-on.svg

  echo "...restore gtk-2.0 gtkrc files"
  cd "$SRC_DIR/main/gtk-2.0"
  mv -f gtkrc-dark.bak gtkrc-dark
  mv -f gtkrc-light.bak gtkrc-light

  echo "...restore gtk-2.0 assets files"
  cd "${SRC_DIR}/assets/gtk-2.0"
  mv -f assets-dark.svg.bak assets-dark.svg
  mv -f assets-light.svg.bak assets-light.svg

  if [[ -d assets-dark-bak ]]; then
    rm -rf assets-dark/
    mv -f assets-dark-bak assets-dark
  fi

  if [[ -d assets-light-bak ]]; then
    rm -rf assets-light/
    mv -f assets-light-bak assets-light
  fi

  echo "...restore cinnamon thumbnail files"
  cd "$SRC_DIR/assets/cinnamon"
  mv -f thumbnail.svg.bak thumbnail.svg
  mv -f thumbnail-dark.png.bak thumbnail-dark.png
  mv -f thumbnail-light.png.bak thumbnail-light.png

  echo "...restore cinnamon assets files"
  cd "$SRC_DIR/assets/cinnamon/common-assets"
  mv -f checkbox.svg.bak checkbox.svg
  mv -f radiobutton.svg.bak radiobutton.svg
  mv -f add-workspace-active.svg.bak add-workspace-active.svg
  mv -f menu-hover.svg.bak menu-hover.svg
  mv -f toggle-on.svg.bak toggle-on.svg
  mv -f corner-ripple.svg.bak corner-ripple.svg

  prompt -w "Restore assets files finished!..."
}

restore_files() {
  local restore_file='false'

  if [[ -f ${SRC_DIR}/sass/gtk/_applications.scss.bak ]]; then

    local restore_file='true'

    cd ${SRC_DIR}/sass/gtk
    rm -rf _applications.scss
    mv -f _applications.scss.bak _applications.scss
    prompt -w "Restore _applications.scss file ..."
  fi

  if [[ -f ${SRC_DIR}/sass/_colors.scss.bak ]]; then

    local restore_file='true'

    cd ${SRC_DIR}/sass
    rm -rf _colors.scss
    mv -f _colors.scss.bak _colors.scss
    prompt -w "Restore _colors.scss file ..."
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

  if [[ -f "${SRC_DIR}"/assets/gtk-3.0/thumbnail.svg.bak ]]; then
    restore_assets_files
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
      theme='true'
      shift
      for theme_color in "${@}"; do
        case "${theme_color}" in
          default)
            theme_colors+=("${THEME_COLOR_VARIANTS[0]}")
            shift
            ;;
          blue)
            theme_colors+=("${THEME_COLOR_VARIANTS[1]}")
            shift
            ;;
          purple)
            theme_colors+=("${THEME_COLOR_VARIANTS[2]}")
            shift
            ;;
          pink)
            theme_colors+=("${THEME_COLOR_VARIANTS[3]}")
            shift
            ;;
          red)
            theme_colors+=("${THEME_COLOR_VARIANTS[4]}")
            shift
            ;;
          orange)
            theme_colors+=("${THEME_COLOR_VARIANTS[5]}")
            shift
            ;;
          yellow)
            theme_colors+=("${THEME_COLOR_VARIANTS[6]}")
            shift
            ;;
          green)
            theme_colors+=("${THEME_COLOR_VARIANTS[7]}")
            shift
            ;;
          grey)
            theme_colors+=("${THEME_COLOR_VARIANTS[8]}")
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

  if [[ "${theme:-}" != 'true' && "${size:-}" != 'true' && "${panel:-}" != 'true' ]]; then
    install_theme
  else
    install_customize_theme && parse_sass && install_theme "${panel_opacity}" "${sidebar_size}" "${theme_color}"
  fi
fi

# Install GDM theme
if [[ "${gdm:-}" == 'true' && "${remove:-}" != 'true' && "$UID" -eq "$ROOT_UID" ]]; then
  install_theme && install_gdm "${dest:-${DEST_DIR}}" "${name:-${THEME_NAME}}" "${color}" "${opacity}" "${theme_color}"
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
