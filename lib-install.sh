# WARNING: Please make this shell not working-directory dependant, for example
# instead of using 'cd blabla', use 'cd "${REPO_DIR}/blabla"'
#
# WARNING: Don't use "cd" in this shell, use it in a subshell instead,
# for example ( cd blabla && do_blabla ) or $( cd .. && do_blabla )
#
# WARNING: Please don't use sudo directly here since it steals our EXIT trap
#
# WARNING: Please set REPO_DIR variable before using this lib

###############################################################################
#                                VARIABLES                                    #
###############################################################################

source "${REPO_DIR}/lib-core.sh"

###############################################################################
#                              DEPENDENCIES                                   #
###############################################################################

install_theme_deps() {
  if ! has_command glib-compile-resources || ! has_command sassc || \
    ! has_command xmllint || [[ ! -r "/usr/share/gtk-engines/murrine.xml" ]]; then
    echo; prompt -w "'glib2.0', 'sassc', 'xmllint', and 'libmurrine' are required for theme installation."

    if has_command zypper; then
      rootify zypper in -y sassc glib2-devel gtk2-engine-murrine libxml2-tools
    elif has_command apt; then
      rootify apt install -y sassc libglib2.0-dev-bin gtk2-engines-murrine libxml2-utils
    elif has_command dnf; then
      rootify dnf install -y sassc glib2-devel gtk-murrine-engine libxml2
    elif has_command yum; then
      rootify yum install -y sassc glib2-devel gtk-murrine-engine libxml2
    elif has_command pacman; then
      rootify pacman -S --noconfirm --needed sassc glib2 gtk-engine-murrine libxml2
    else
      prompt -w "WARNING: We're sorry, your distro isn't officially supported yet."
      prompt -w "INSTRUCTION: Please make sure you have installed all of the required dependencies. We'll continue the installation in 15 seconds"
      prompt -w "INSTRUCTION: Press 'ctrl'+'c' to cancel the installation if you haven't install them yet"
      start_animation; sleep 15; stop_animation
    fi
  fi
}

install_gdm_deps() {
  #TODO: @vince, do we also need "sassc" here?

  if ! has_command glib-compile-resources || ! has_command xmllint || \
    ! has_command sassc; then
    echo; prompt -w "'glib2.0', 'xmllint', and 'sassc' are required for theme installation."

    if has_command zypper; then
      rootify zypper in -y glib2-devel libxml2-tools sassc
    elif has_command apt; then
      rootify apt install -y libglib2.0-dev-bin libxml2-utils sassc
    elif has_command dnf; then
      rootify dnf install -y glib2-devel libxml2 sassc
    elif has_command yum; then
      rootify yum install -y glib2-devel libxml2 sassc
    elif has_command pacman; then
      rootify pacman -S --noconfirm --needed glib2 libxml2 sassc
    else
      prompt -w "WARNING: We're sorry, your distro isn't officially supported yet."
      prompt -w "INSTRUCTION: Please make sure you have installed all of the required dependencies. We'll continue the installation in 15 seconds"
      prompt -w "INSTRUCTION: Press 'ctrl'+'c' to cancel the installation if you haven't install them yet"
      start_animation; sleep 15; stop_animation
    fi
  fi
}

install_beggy_deps() {
  if ! has_command convert; then
    echo; prompt -w "'imagemagick' are required for background editing."

    if has_command zypper; then
      rootify zypper in -y ImageMagick
    elif has_command apt; then
      rootify apt install -y imagemagick
    elif has_command dnf; then
      rootify dnf install -y ImageMagick
    elif has_command yum; then
      rootify yum install -y ImageMagick
    elif has_command pacman; then
      rootify pacman -S --noconfirm --needed imagemagick
    else
      prompt -w "WARNING: We're sorry, your distro isn't officially supported yet."
      prompt -w "INSTRUCTION: Please make sure you have installed all of the required dependencies. We'll continue the installation in 15 seconds"
      prompt -w "INSTRUCTION: Press 'ctrl'+'c' to cancel the installation if you haven't install them yet"
      start_animation; sleep 15; stop_animation
    fi
  fi
}

install_dialog_deps() {
  if ! has_command dialog; then
    echo; prompt -w "'dialog' are required for this option."

    if has_command zypper; then
      rootify zypper in -y dialog
    elif has_command apt; then
      rootify apt install -y dialog
    elif has_command dnf; then
      rootify dnf install -y dialog
    elif has_command yum; then
      rootify yum install -y dialog
    elif has_command pacman; then
      rootify pacman -S --noconfirm --needed dialog
    else
      prompt -w "WARNING: We're sorry, your distro isn't officially supported yet."
      prompt -w "INSTRUCTION: Please make sure you have installed all of the required dependencies. We'll continue the installation in 15 seconds"
      prompt -w "INSTRUCTION: Press 'ctrl'+'c' to cancel the installation if you haven't install them yet"
      start_animation; sleep 15; stop_animation
    fi
  fi
}

###############################################################################
#                              THEME MODULES                                  #
###############################################################################

install_beggy() {
  local CONVERT_OPT=""

  [[ "${no_blur}" == "false" ]] && CONVERT_OPT+=" -scale 1280x -blur 0x50 "
  [[ "${no_darken}" == "false" ]] && CONVERT_OPT+=" -fill black -colorize 45% "

  case "${background}" in
    blank)
      cp -r "${THEME_SRC_DIR}/assets/gnome-shell/common-assets/background-blank.png"          "${WHITESUR_TMP_DIR}/beggy.png" ;;
    default)
      if [[ "${no_blur}" == "false" && "${no_darken}" == "true" ]]; then
        cp -r "${THEME_SRC_DIR}/assets/gnome-shell/common-assets/background-blur.png"         "${WHITESUR_TMP_DIR}/beggy.png"
      elif [[ "${no_blur}" == "false" && "${no_darken}" == "false" ]]; then
        cp -r "${THEME_SRC_DIR}/assets/gnome-shell/common-assets/background-blur-darken.png"  "${WHITESUR_TMP_DIR}/beggy.png"
      elif [[ "${no_blur}" == "true" && "${no_darken}" == "true" ]]; then
        cp -r "${THEME_SRC_DIR}/assets/gnome-shell/common-assets/background-default.png"      "${WHITESUR_TMP_DIR}/beggy.png"
      else
        cp -r "${THEME_SRC_DIR}/assets/gnome-shell/common-assets/background-darken.png"       "${WHITESUR_TMP_DIR}/beggy.png"
      fi
      ;;
    *)
      if [[ "${no_blur}" == "false" || "${darken}" == "true" ]]; then
        install_beggy_deps && convert "${background}" ${CONVERT_OPT}                          "${WHITESUR_TMP_DIR}/beggy.png"
      else
        cp -r "${background}"                                                                 "${WHITESUR_TMP_DIR}/beggy.png"
      fi
      ;;
  esac
}

install_darky() {
  local opacity="$(destify ${1})"
  local theme="$(destify ${2})"

  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-3.0/gtk-dark.scss"                            "${WHITESUR_TMP_DIR}/darky-3.css"
  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-4.0/gtk-dark.scss"                            "${WHITESUR_TMP_DIR}/darky-4.css"
}

install_xfwmy() {
  local color="$(destify ${1})"

  local TARGET_DIR="${dest}/${name}${color}"
  local HDPI_TARGET_DIR="${dest}/${name}${color}-hdpi"
  local XHDPI_TARGET_DIR="${dest}/${name}${color}-xhdpi"

  mkdir -p                                                                                    "${TARGET_DIR}/xfwm4"
  cp -r "${THEME_SRC_DIR}/assets/xfwm4/assets${color}/"*".png"                                "${TARGET_DIR}/xfwm4"
  cp -r "${THEME_SRC_DIR}/main/xfwm4/themerc${color}"                                         "${TARGET_DIR}/xfwm4/themerc"

  mkdir -p                                                                                    "${HDPI_TARGET_DIR}/xfwm4"
  cp -r "${THEME_SRC_DIR}/assets/xfwm4/assets${color}-hdpi/"*".png"                           "${HDPI_TARGET_DIR}/xfwm4"
  cp -r "${THEME_SRC_DIR}/main/xfwm4/themerc${color}"                                         "${HDPI_TARGET_DIR}/xfwm4/themerc"

  mkdir -p                                                                                    "${XHDPI_TARGET_DIR}/xfwm4"
  cp -r "${THEME_SRC_DIR}/assets/xfwm4/assets${color}-xhdpi/"*".png"                          "${XHDPI_TARGET_DIR}/xfwm4"
  cp -r "${THEME_SRC_DIR}/main/xfwm4/themerc${color}"                                         "${XHDPI_TARGET_DIR}/xfwm4/themerc"
}

install_shelly() {
  local color="$(destify ${1})"
  local opacity="$(destify ${2})"
  local alt="$(destify ${3})"
  local theme="$(destify ${4})"
  local icon="$(destify ${5})"
  local TARGET_DIR=

  if [[ -z "${6}" ]]; then
    TARGET_DIR="${dest}/${name}${color}${opacity}${alt}${theme}/gnome-shell"
  else TARGET_DIR="${6}"; fi

  mkdir -p                                                                                    "${TARGET_DIR}"
  mkdir -p                                                                                    "${TARGET_DIR}/assets"
  cp -r "${THEME_SRC_DIR}/assets/gnome-shell/icons"                                           "${TARGET_DIR}"
  cp -r "${THEME_SRC_DIR}/main/gnome-shell/pad-osd.css"                                       "${TARGET_DIR}"

  if [[ "${GNOME_VERSION}" == 'new'  ]]; then
    sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gnome-shell/shell-40-0/gnome-shell${color}.scss" "${TARGET_DIR}/gnome-shell.css"
  else
    sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gnome-shell/shell-3-28/gnome-shell${color}.scss" "${TARGET_DIR}/gnome-shell.css"
  fi

  cp -r "${THEME_SRC_DIR}/assets/gnome-shell/common-assets/"*".svg"                           "${TARGET_DIR}/assets"

  if [[ "${theme}" != '' ]]; then
    cp -r "${THEME_SRC_DIR}/assets/gnome-shell/common-assets${theme}/"*".svg"                 "${TARGET_DIR}/assets"
  fi

  cp -r "${THEME_SRC_DIR}/assets/gnome-shell/assets${color}/"*".svg"                          "${TARGET_DIR}/assets"
  cp -r "${THEME_SRC_DIR}/assets/gnome-shell/activities/activities${icon}.svg"                "${TARGET_DIR}/assets/activities.svg"
  cp -r "${WHITESUR_TMP_DIR}/beggy.png"                                                       "${TARGET_DIR}/assets/background.png"

  (
    cd "${TARGET_DIR}"
    mv -f "assets/no-events.svg" "no-events.svg"
    mv -f "assets/process-working.svg" "process-working.svg"
    mv -f "assets/no-notifications.svg" "no-notifications.svg"
  )

  if [[ "${alt}" == '-alt' || "${opacity}" == '-solid' ]] &&  [[ "${color}" == '-light' ]]; then
    cp -r "${THEME_SRC_DIR}/assets/gnome-shell/activities-black/activities${icon}.svg"        "${TARGET_DIR}/assets/activities.svg"
    cp -r "${THEME_SRC_DIR}/assets/gnome-shell/activities/activities${icon}.svg"              "${TARGET_DIR}/assets/activities-white.svg"
  fi
}

install_theemy() {
  local color="$(destify ${1})"
  local opacity="$(destify ${2})"
  local alt="$(destify ${3})"
  local theme="$(destify ${4})"
  local icon="$(destify ${5})"

  local TARGET_DIR="${dest}/${name}${color}${opacity}${alt}${theme}"
  local TMP_DIR_T="${WHITESUR_TMP_DIR}/gtk-3.0${color}${opacity}${alt}${theme}"
  local TMP_DIR_F="${WHITESUR_TMP_DIR}/gtk-4.0${color}${opacity}${alt}${theme}"

  mkdir -p                                                                                    "${TARGET_DIR}"
  local desktop_entry="
  [Desktop Entry]
  Type=X-GNOME-Metatheme
  Name=${name}${color}${opacity}${alt}${theme}
  Comment=A MacOS BigSur like Gtk+ theme based on Elegant Design
  Encoding=UTF-8

  [X-GNOME-Metatheme]
  GtkTheme=${name}${color}${opacity}${alt}${theme}
  MetacityTheme=${name}${color}${opacity}${alt}${theme}
  IconTheme=${name}${color}
  CursorTheme=${name}${color}
  ButtonLayout=close,minimize,maximize:menu"
  echo "${desktop_entry}" >                                                                   "${TARGET_DIR}/index.theme"

  #--------------------GTK-3.0--------------------#

  mkdir -p                                                                                    "${TMP_DIR_T}"
  cp -r "${THEME_SRC_DIR}/assets/gtk/common-assets/assets"                                    "${TMP_DIR_T}"
  cp -r "${THEME_SRC_DIR}/assets/gtk/common-assets/sidebar-assets/"*".png"                    "${TMP_DIR_T}/assets"
  cp -r "${THEME_SRC_DIR}/assets/gtk/windows-assets/titlebutton${alt}"                        "${TMP_DIR_T}/windows-assets"

  if [[ "${theme}" != '' ]]; then
    cp -r "${THEME_SRC_DIR}/assets/gtk/common-assets/assets${theme}/"*".png"                  "${TMP_DIR_T}/assets"
  fi

  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-3.0/gtk${color}.scss"                         "${TMP_DIR_T}/gtk.css"
  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-3.0/gtk-dark.scss"                            "${TMP_DIR_T}/gtk-dark.css"

  mkdir -p                                                                                    "${TARGET_DIR}/gtk-3.0"
  cp -r "${THEME_SRC_DIR}/assets/gtk/thumbnails/thumbnail${color}${theme}.png"                "${TARGET_DIR}/gtk-3.0/thumbnail.png"
  echo '@import url("resource:///org/gnome/theme/gtk.css");' >                                "${TARGET_DIR}/gtk-3.0/gtk.css"
  echo '@import url("resource:///org/gnome/theme/gtk-dark.css");' >                           "${TARGET_DIR}/gtk-3.0/gtk-dark.css"
  glib-compile-resources --sourcedir="${TMP_DIR_T}" --target="${TARGET_DIR}/gtk-3.0/gtk.gresource" "${THEME_SRC_DIR}/main/gtk-3.0/gtk.gresource.xml"

  #--------------------GTK-4.0--------------------#

  mkdir -p                                                                                    "${TMP_DIR_F}"
  cp -r "${TMP_DIR_T}/assets"                                                                 "${TMP_DIR_F}"
  cp -r "${TMP_DIR_T}/windows-assets"                                                         "${TMP_DIR_F}"

  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-4.0/gtk${color}.scss"                         "${TMP_DIR_F}/gtk.css"
  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-4.0/gtk-dark.scss"                            "${TMP_DIR_F}/gtk-dark.css"

  mkdir -p                                                                                    "${TARGET_DIR}/gtk-4.0"
  cp -r "${THEME_SRC_DIR}/assets/gtk/thumbnails/thumbnail${color}${theme}.png"                "${TARGET_DIR}/gtk-4.0/thumbnail.png"
  echo '@import url("resource:///org/gnome/theme/gtk.css");' >                                "${TARGET_DIR}/gtk-4.0/gtk.css"
  echo '@import url("resource:///org/gnome/theme/gtk-dark.css");' >                           "${TARGET_DIR}/gtk-4.0/gtk-dark.css"
  glib-compile-resources --sourcedir="${TMP_DIR_F}" --target="${TARGET_DIR}/gtk-4.0/gtk.gresource" "${THEME_SRC_DIR}/main/gtk-4.0/gtk.gresource.xml"

  #----------------Cinnamon-----------------#

  mkdir -p                                                                                    "${TARGET_DIR}/cinnamon"
  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/cinnamon/cinnamon${color}.scss"                   "${TARGET_DIR}/cinnamon/cinnamon.css"
  cp -r "${THEME_SRC_DIR}/assets/cinnamon/common-assets"                                      "${TARGET_DIR}/cinnamon/assets"

  if [[ ${theme} != '' ]]; then
    cp -r "${THEME_SRC_DIR}/assets/cinnamon/common-assets${theme}/"*".svg"                    "${TARGET_DIR}/cinnamon/assets"
  fi

  cp -r "${THEME_SRC_DIR}/assets/cinnamon/assets${color}/"*".svg"                             "${TARGET_DIR}/cinnamon/assets"
  cp -r "${THEME_SRC_DIR}/assets/cinnamon/thumbnails/thumbnail${color}${theme}.png"           "${TARGET_DIR}/cinnamon/thumbnail.png"

  #----------------Misc------------------#

  mkdir -p                                                                                    "${TARGET_DIR}/gtk-2.0"
  cp -r "${THEME_SRC_DIR}/main/gtk-2.0/gtkrc${color}${theme}"                                 "${TARGET_DIR}/gtk-2.0/gtkrc"
  cp -r "${THEME_SRC_DIR}/main/gtk-2.0/menubar-toolbar${color}.rc"                            "${TARGET_DIR}/gtk-2.0/menubar-toolbar.rc"
  cp -r "${THEME_SRC_DIR}/main/gtk-2.0/common/"*".rc"                                         "${TARGET_DIR}/gtk-2.0"
  cp -r "${THEME_SRC_DIR}/assets/gtk-2.0/assets${color}"                                      "${TARGET_DIR}/gtk-2.0/assets"

  if [[ "${theme}" != '' ]]; then
    cp -r "${THEME_SRC_DIR}/assets/gtk-2.0/assets${color}${theme}/"*".png"                    "${TARGET_DIR}/gtk-2.0/assets"
  fi

  mkdir -p                                                                                    "${TARGET_DIR}/metacity-1"
  cp -r "${THEME_SRC_DIR}/main/metacity-1/metacity-theme${color}.xml"                         "${TARGET_DIR}/metacity-1/metacity-theme-1.xml"
  cp -r "${THEME_SRC_DIR}/main/metacity-1/metacity-theme-3.xml"                               "${TARGET_DIR}/metacity-1"
  cp -r "${THEME_SRC_DIR}/assets/metacity-1/titlebuttons${color}"                             "${TARGET_DIR}/metacity-1/titlebuttons"
  cp -r "${THEME_SRC_DIR}/assets/metacity-1/thumbnail${color}.png"                            "${TARGET_DIR}/metacity-1/thumbnail.png"
  ( cd "${TARGET_DIR}/metacity-1" && ln -s "metacity-theme-1.xml" "metacity-theme-2.xml" )

  mkdir -p                                                                                    "${TARGET_DIR}/plank"
  cp -r "${THEME_SRC_DIR}/other/plank/theme${color}/"*".theme"                                "${TARGET_DIR}/plank"
}

remove_packy() {
  rm -rf "${dest}/${name}$(destify ${1})$(destify ${2})$(destify ${3})$(destify ${4})"
  rm -rf "${dest}/${name}$(destify ${1})"
  rm -rf "${dest}/${name}$(destify ${1})-hdpi"
  rm -rf "${dest}/${name}$(destify ${1})-xhdpi"

  # Backward compatibility
  rm -rf "${dest}/${name}$(destify ${1})-mdpi"
}

###############################################################################
#                                   THEMES                                    #
###############################################################################

install_themes() {
  # "install_theemy" and "install_shelly" require "gtk_base", so multithreading
  # isn't possible

  start_animation; install_beggy

  for opacity in "${opacities[@]}"; do
    for alt in "${alts[@]}"; do
      for theme in "${themes[@]}"; do
        install_xfwmy "${color}"

        for color in "${colors[@]}"; do
          gtk_base "${color}" "${opacity}" "${theme}" "${compact}"
          install_theemy "${color}" "${opacity}" "${alt}" "${theme}" "${icon}"
          install_shelly "${color}" "${opacity}" "${alt}" "${theme}" "${icon}"
        done
      done
    done
  done

  stop_animation
}

remove_themes() {
  process_ids=()

  for color in "${COLOR_VARIANTS[@]}"; do
    for opacity in "${OPACITY_VARIANTS[@]}"; do
      for alt in "${ALT_VARIANTS[@]}"; do
        for theme in "${THEME_VARIANTS[@]}"; do
          remove_packy "${color}" "${opacity}" "${alt}" "${theme}" &
          process_ids+=("${!}")
        done
      done
    done
  done

  wait ${process_ids[*]} &> /dev/null
}

install_gdm_theme() {
  start_animation
  local TARGET=

  # Let's go!
  rm -rf "${WHITESUR_GS_DIR}"; install_beggy
  gtk_base "${colors[0]}" "${opacities[0]}" "${themes[0]}"

  if check_theme_file "${COMMON_CSS_FILE}"; then # CSS-based theme
    install_shelly "${colors[0]}" "${opacities[0]}" "${alts[0]}" "${themes[0]}" "${icon}" "${WHITESUR_GS_DIR}"
    sed $SED_OPT "s|assets|${WHITESUR_GS_DIR}/assets|" "${WHITESUR_GS_DIR}/gnome-shell.css"

    if check_theme_file "${UBUNTU_CSS_FILE}"; then
      TARGET="${UBUNTU_CSS_FILE}"
    elif check_theme_file "${ZORIN_CSS_FILE}"; then
      TARGET="${ZORIN_CSS_FILE}"
    fi

    backup_file "${COMMON_CSS_FILE}"; backup_file "${TARGET}"
    ln -sf "${WHITESUR_GS_DIR}/gnome-shell.css" "${COMMON_CSS_FILE}"
    ln -sf "${WHITESUR_GS_DIR}/gnome-shell.css" "${TARGET}"

    # Fix previously installed WhiteSur
    restore_file "${ETC_CSS_FILE}"
  else # GR-based theme
    install_shelly "${colors[0]}" "${opacities[0]}" "${alts[0]}" "${themes[0]}" "${icon}" "${WHITESUR_TMP_DIR}/shelly"
    sed $SED_OPT "s|assets|resource:///org/gnome/shell/theme/assets|" "${WHITESUR_TMP_DIR}/shelly/gnome-shell.css"

    if check_theme_file "$POP_OS_GR_FILE"; then
      TARGET="${POP_OS_GR_FILE}"
    elif check_theme_file "$YARU_GR_FILE"; then
      TARGET="${YARU_GR_FILE}"
    elif check_theme_file "$MISC_GR_FILE"; then
      TARGET="${MISC_GR_FILE}"
    fi

    backup_file "${TARGET}"
    glib-compile-resources --sourcedir="${WHITESUR_TMP_DIR}/shelly" --target="${TARGET}" "${GS_GR_XML_FILE}"

    # Fix previously installed WhiteSur
    restore_file "${ETC_GR_FILE}"
  fi

  stop_animation
}

revert_gdm_theme() {
  rm -rf "${WHITESUR_GS_DIR}"
  restore_file "${COMMON_CSS_FILE}"; restore_file "${UBUNTU_CSS_FILE}"
  restore_file "${ZORIN_CSS_FILE}"; restore_file "${ETC_CSS_FILE}"
  restore_file "${POP_OS_GR_FILE}"; restore_file "${YARU_GR_FILE}"
  restore_file "${MISC_GR_FILE}"; restore_file "${ETC_GR_FILE}"
}

###############################################################################
#                                  FIREFOX                                    #
###############################################################################

install_firefox_theme() {
  #TODO: add support for Snap

  if has_flatpak_app org.mozilla.firefox; then
    local TARGET_DIR="${FIREFOX_FLATPAK_THEME_DIR}"
  else
    local TARGET_DIR="${FIREFOX_THEME_DIR}"
  fi

  remove_firefox_theme
  userify mkdir -p                                                                              "${TARGET_DIR}"
  userify cp -rf "${FIREFOX_SRC_DIR}"/*                                                         "${TARGET_DIR}"
  config_firefox
}

config_firefox() {
  if has_flatpak_app org.mozilla.firefox; then
    local TARGET_DIR="${FIREFOX_FLATPAK_THEME_DIR}"
    local FIREFOX_DIR="${FIREFOX_FLATPAK_DIR_HOME}"
  else
    local TARGET_DIR="${FIREFOX_THEME_DIR}"
    local FIREFOX_DIR="${FIREFOX_DIR_HOME}"
  fi

  killall "firefox" "firefox-bin" &> /dev/null || true

  for d in "${FIREFOX_DIR}/"*"default"*; do
    if [[ -f "${d}/prefs.js" ]]; then
      rm -rf                                                                                    "${d}/chrome"
      userify ln -sf "${TARGET_DIR}"                                                            "${d}/chrome"
      userify_file                                                                              "${d}/prefs.js"
      echo "user_pref(\"toolkit.legacyUserProfileCustomizations.stylesheets\", true);" >>       "${d}/prefs.js"
      echo "user_pref(\"browser.tabs.drawInTitlebar\", true);" >>                               "${d}/prefs.js"
      echo "user_pref(\"browser.uidensity\", 0);" >>                                            "${d}/prefs.js"
      echo "user_pref(\"layers.acceleration.force-enabled\", true);" >>                         "${d}/prefs.js"
      echo "user_pref(\"mozilla.widget.use-argb-visuals\", true);" >>                           "${d}/prefs.js"
    fi
  done
}

edit_firefox_theme_prefs() {
  if has_flatpak_app org.mozilla.firefox; then
    local TARGET_DIR="${FIREFOX_FLATPAK_THEME_DIR}"
  else
    local TARGET_DIR="${FIREFOX_THEME_DIR}"
  fi

  [[ ! -d "${TARGET_DIR}" ]] && install_firefox_theme ; config_firefox
  userify ${EDITOR:-nano}                                                                       "${TARGET_DIR}/userChrome.css"
  userify ${EDITOR:-nano}                                                                       "${TARGET_DIR}/customChrome.css"
}

remove_firefox_theme() {
  rm -rf "${FIREFOX_DIR_HOME}/"*"default"*"/chrome"
  rm -rf "${FIREFOX_THEME_DIR}"
  rm -rf "${FIREFOX_FLATPAK_DIR_HOME}/"*"default"*"/chrome"
  rm -rf "${FIREFOX_FLATPAK_THEME_DIR}"
}

###############################################################################
#                               DASH TO DOCK                                  #
###############################################################################

install_dash_to_dock_theme() {
  gtk_base "${colors[0]}" "${opacities[0]}" "${themes[0]}"

  if [[ -d "${DASH_TO_DOCK_DIR_HOME}" ]]; then
    backup_file "${DASH_TO_DOCK_DIR_HOME}/stylesheet.css" "userify"
    userify_file                                                                                "${DASH_TO_DOCK_DIR_HOME}/stylesheet.css"
    userify sassc ${SASSC_OPT} "${DASH_TO_DOCK_SRC_DIR}/stylesheet$(destify ${colors[0]}).scss" "${DASH_TO_DOCK_DIR_HOME}/stylesheet.css"
  elif [[ -d "${DASH_TO_DOCK_DIR_ROOT}" ]]; then
    backup_file "${DASH_TO_DOCK_DIR_ROOT}/stylesheet.css" "rootify"
    rootify sassc ${SASSC_OPT} "${DASH_TO_DOCK_SRC_DIR}/stylesheet$(destify ${colors[0]}).scss" "${DASH_TO_DOCK_DIR_ROOT}/stylesheet.css"
  fi

  userify dbus-launch dconf write /org/gnome/shell/extensions/dash-to-dock/apply-custom-theme true
}

revert_dash_to_dock_theme() {
  if [[ -d "${DASH_TO_DOCK_DIR_HOME}" ]]; then
    restore_file "${DASH_TO_DOCK_DIR_HOME}/stylesheet.css" "userify"
  elif [[ -d "${DASH_TO_DOCK_DIR_ROOT}" ]]; then
    restore_file "${DASH_TO_DOCK_DIR_ROOT}/stylesheet.css" "rootify"
  fi
}

###############################################################################
#                              FLATPAK & SNAP                                 #
###############################################################################

connect_flatpak() {
  rootify flatpak override --filesystem=~/.themes
}

disconnect_flatpak() {
  rootify flatpak override --nofilesystem=~/.themes
}

connect_snap() {
  rootify snap install whitesur-gtk-theme

  for i in $(snap connections | grep gtk-common-themes | awk '{print $2}' | cut -f1 -d: | sort -u); do
    rootify snap connect "${i}:gtk-3-themes"    "whitesur-gtk-theme:gtk-3-themes"
    rootify snap connect "${i}:icon-themes"     "whitesur-gtk-theme:icon-themes"
  done
}

disconnect_snap() {
  for i in $(snap connections | grep gtk-common-themes | awk '{print $2}' | cut -f1 -d: | sort -u); do
    rootify snap disconnect "${i}:gtk-3-themes" "whitesur-gtk-theme:gtk-3-themes"
    rootify snap disconnect "${i}:icon-themes"  "whitesur-gtk-theme:icon-themes"
  done
}

#########################################################################
#                               GTK BASE                                #
#########################################################################

gtk_base() {
  cp -rf "${THEME_SRC_DIR}/sass/_gtk-base"{".scss","-temp.scss"}

  # Theme base options
  sed $SED_OPT "/\$laptop/s/false/${compact}/"                                  "${THEME_SRC_DIR}/sass/_gtk-base-temp.scss"

  if [[ "${opacity}" == 'solid' ]]; then
    sed $SED_OPT "/\$trans/s/true/false/"                                       "${THEME_SRC_DIR}/sass/_gtk-base-temp.scss"
  fi

  if [[ "${color}" == 'light' && ${opacity} == 'solid' ]]; then
    sed $SED_OPT "/\$black/s/false/true/"                                       "${THEME_SRC_DIR}/sass/_gtk-base-temp.scss"
  fi

  if [[ "${theme}" != '' ]]; then
    sed $SED_OPT "/\$theme/s/default/${theme}/"                                 "${THEME_SRC_DIR}/sass/_gtk-base-temp.scss"
  fi
}

###############################################################################
#                               CUSTOMIZATIONS                                #
###############################################################################

customize_theme() {
  cp -rf "${THEME_SRC_DIR}/sass/_theme-options"{".scss","-temp.scss"}

  # Change gnome-shell panel transparency
  if [[ "${panel_opacity}" != 'default' ]]; then
    prompt -s "Changing panel transparency ..."
    sed $SED_OPT "/\$panel_opacity/s/0.15/0.${panel_opacity}/"                  "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change gnome-shell show apps button style
  if [[ "${showapps_normal}" == 'true' ]]; then
    prompt -s "Changing gnome-shell show apps button style ..."
    sed $SED_OPT "/\$showapps_button/s/bigsur/normal/"                          "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change Nautilus sidarbar size
  if [[ "${sidebar_size}" != 'default' ]]; then
    prompt -s "Changing Nautilus sidebar size ..."
    sed $SED_OPT "/\$sidebar_size/s/200px/${sidebar_size}px/"                   "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change Nautilus style
  if [[ "${nautilus_style}" != 'stable' ]]; then
    prompt -s "Changing Nautilus style ..."
    sed $SED_OPT "/\$nautilus_style/s/stable/${nautilus_style}/"                "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change Nautilus titlebutton placement style
  if [[ "${right_placement}" == 'true' ]]; then
    prompt -s "Changing Nautilus titlebutton placement style ..."
    sed $SED_OPT "/\$placement/s/left/right/"                                   "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change maximized window radius
  if [[ "${max_round}" == 'true' ]]; then
    prompt -s "Changing maximized window style ..."
    sed $SED_OPT "/\$max_window_style/s/square/round/"                          "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  if [[ "${compact}" == 'false' ]]; then
    prompt -s "Changing Definition mode to HD (Bigger font, Bigger size) ..."
    #FIXME: @vince is it not implemented yet?
  fi
}

#-----------------------------------DIALOGS------------------------------------#

# The default values here should get manually set and updated. Some of default
# values are taken from _variables.scss

show_panel_opacity_dialog() {
  if [[ -x /usr/bin/dialog ]]; then
    tui=$(dialog --backtitle "${THEME_NAME} gtk theme installer" \
        --radiolist "Choose your panel background opacity
                (Default is 0.15. The less value, the more transparency!):" 20 50 10 \
      0 "${PANEL_OPACITY_VARIANTS[0]}" on    \
      1 "0.${PANEL_OPACITY_VARIANTS[1]}" off \
      2 "0.${PANEL_OPACITY_VARIANTS[2]}" off \
      3 "0.${PANEL_OPACITY_VARIANTS[3]}" off \
      4 "0.${PANEL_OPACITY_VARIANTS[4]}" off --output-fd 1 )
      case "$tui" in
        0) panel_opacity="${PANEL_OPACITY_VARIANTS[0]}" ;;
        1) panel_opacity="${PANEL_OPACITY_VARIANTS[1]}" ;;
        2) panel_opacity="${PANEL_OPACITY_VARIANTS[2]}" ;;
        3) panel_opacity="${PANEL_OPACITY_VARIANTS[3]}" ;;
        4) panel_opacity="${PANEL_OPACITY_VARIANTS[4]}" ;;
        *) operation_aborted ;;
      esac
  fi

  clear
}

show_sidebar_size_dialog() {
  if [[ -x /usr/bin/dialog ]]; then
    tui=$(dialog --backtitle "${THEME_NAME} gtk theme installer" \
    --radiolist "Choose your Nautilus sidebar size (default is 200px width):" 15 40 5 \
      0 "${SIDEBAR_SIZE_VARIANTS[0]}" on  \
      1 "${SIDEBAR_SIZE_VARIANTS[1]}px" off \
      2 "${SIDEBAR_SIZE_VARIANTS[2]}px" off \
      3 "${SIDEBAR_SIZE_VARIANTS[3]}px" off \
      4 "${SIDEBAR_SIZE_VARIANTS[4]}px" off --output-fd 1 )
      case "$tui" in
        0) sidebar_size="${SIDEBAR_SIZE_VARIANTS[0]}" ;;
        1) sidebar_size="${SIDEBAR_SIZE_VARIANTS[1]}" ;;
        2) sidebar_size="${SIDEBAR_SIZE_VARIANTS[2]}" ;;
        3) sidebar_size="${SIDEBAR_SIZE_VARIANTS[3]}" ;;
        4) sidebar_size="${SIDEBAR_SIZE_VARIANTS[4]}" ;;
        *) operation_aborted ;;
      esac
  fi

  clear
}

show_nautilus_style_dialog() {
  if [[ -x /usr/bin/dialog ]]; then
    tui=$(dialog --backtitle "${THEME_NAME} gtk theme installer" \
    --radiolist "Choose your Nautilus style (default is BigSur-like style):" 15 40 5 \
      0 "${NAUTILUS_STYLE_VARIANTS[0]}" on \
      1 "${NAUTILUS_STYLE_VARIANTS[1]}" off \
      1 "${NAUTILUS_STYLE_VARIANTS[2]}" off \
      2 "${NAUTILUS_STYLE_VARIANTS[3]}" off --output-fd 1 )
      case "$tui" in
        0) nautilus_style="${NAUTILUS_STYLE_VARIANTS[0]}" ;;
        1) nautilus_style="${NAUTILUS_STYLE_VARIANTS[1]}" ;;
        2) nautilus_style="${NAUTILUS_STYLE_VARIANTS[2]}" ;;
        3) nautilus_style="${NAUTILUS_STYLE_VARIANTS[3]}" ;;
        *) operation_aborted ;;
      esac
  fi

  clear
}

show_needed_dialogs() {
  if [[ "${need_dialog[@]}" =~ "true" ]]; then install_dialog_deps; fi

  if [[ "${need_dialog["-p"]}" == "true" ]]; then show_panel_opacity_dialog; fi
  if [[ "${need_dialog["-s"]}" == "true" ]]; then show_sidebar_size_dialog; fi
  if [[ "${need_dialog["-N"]}" == "true" ]]; then show_nautilus_style_dialog; fi
}
