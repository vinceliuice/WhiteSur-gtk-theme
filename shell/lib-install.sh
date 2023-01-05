# WARNING: Please make this shell not working-directory dependant, for example
# instead of using 'ls blabla', use 'ls "${REPO_DIR}/blabla"'
#
# WARNING: Don't use "cd" in this shell, use it in a subshell instead,
# for example ( cd blabla && do_blabla ) or $( cd .. && do_blabla )

###############################################################################
#                                VARIABLES                                    #
###############################################################################

source "${REPO_DIR}/shell/lib-core.sh"
source "${REPO_DIR}/shell/lib-flatpak.sh"
WHITESUR_SOURCE+=("lib-install.sh")

###############################################################################
#                              DEPENDENCIES                                   #
###############################################################################

# Be careful of some distro mechanism, some of them use rolling-release
# based installation instead of point-release, e.g., Arch Linux

# Rolling-release based distro doesn't have a seprate repo for each different
# build. This can cause a system call error since an app require the compatible
# version of dependencies. In other words, if you install an new app (which you
# definitely reinstall/upgrade the dependency for that app), but your other
# dependencies are old/expired, you'll end up with broken system.

# That's why we need a full system upgrade there

#---------------------SWUPD--------------------#
# 'swupd' bundles just don't make any sense. It takes about 30GB of space only
# for installing a util, e.g. 'sassc' (from 'desktop-dev' bundle, or
# 'os-utils-gui-dev' bundle, or any other 'sassc' provider bundle)

# Manual package installation is needed for that, but please don't use 'dnf'.
# The known worst impact of using 'dnf' is you install 'sassc' and then you
# remove it, and you run 'sudo dnf upgrade', and boom! Your 'sudo' and other
# system utilities have gone!

#----------------------APT---------------------#
# Some apt version doesn't update the repo list before it install some app.
# It may cause "unable to fetch..." when you're trying to install them

#--------------------PACMAN--------------------#
# 'Syu' (with a single y) may causes "could not open ... decompression failed"
# and "target not found <package>". We got to force 'pacman' to update the repos

#--------------------OTHERS--------------------#
# Sometimes, some Ubuntu distro doesn't enable automatic time. This can cause
# 'Release file for ... is not valid yet'. This may also happen on other distros

#============================================#

#-------------------Prepare------------------#
installation_sorry() {
  prompt -w "WARNING: We're sorry, your distro isn't officially supported yet."
  prompt -i "INSTRUCTION: Please make sure you have installed all of the required dependencies. We'll continue the installation in 15 seconds"
  prompt -i "INSTRUCTION: Press 'ctrl'+'c' to cancel the installation if you haven't install them yet"
  start_animation; sleep 15; stop_animation
}

prepare_deps() {
  local remote_time=""
  local local_time=""

  prompt -i "DEPS: Checking your internet connection..."

  local_time="$(date -u "+%s")"

  if ! remote_time="$(get_utc_epoch_time)"; then
    prompt -e "DEPS ERROR: You have an internet connection issue\n"; exit 1
  fi

  # 5 minutes is the maximum reasonable time delay, so we choose '4' here just
  # in case
  if (( local_time < remote_time-(4*60) )); then
    prompt -w "DEPS: Your system clock is wrong"
    prompt -i "DEPS: Updating your system clock..."
    # Add "+ 25" here to accomodate potential time delay by sudo prompt
    sudo date -s "@$((remote_time + 25))"; sudo hwclock --systohc
  fi
}

prepare_swupd() {
  [[ "${swupd_prepared}" == "true" ]] && return 0

  local remove=""
  local ver=""
  local conf=""
  local dist=""

  if has_command dnf; then
    prompt -w "CLEAR LINUX: You have 'dnf' installed in your system. It may break your system especially when you remove a package"
    confirm remove "CLEAR LINUX: You wanna remove it?"; echo
  fi

  if ! sudo swupd update -y; then
    ver="$(curl -s -o - "${swupd_ver_url}")"
    dist="NAME=\"Clear Linux OS\"\nVERSION=1\nID=clear-linux-os\nID_LIKE=clear-linux-os\n"
    dist+="VERSION_ID=${ver}\nANSI_COLOR=\"1;35\"\nSUPPORT_URL=\"https://clearlinux.org\"\nBUILD_ID=${ver}"

    prompt -w "\n  CLEAR LINUX: Your 'swupd' is broken"
    prompt -i "CLEAR LINUX: Patching 'swupd' distro version detection and try again...\n"
    sudo rm -rf "/etc/os-release"; echo -e "${dist}" | sudo tee                         "/usr/lib/os-release" > /dev/null
    sudo ln -s "/usr/lib/os-release" "/etc/os-release"

    sudo swupd update -y
  fi

  if ! has_command bsdtar; then sudo swupd bundle-add libarchive; fi
  if [[ "${remove}" == "y" ]]; then sudo swupd bundle-remove -y dnf; fi

  swupd_prepared="true"
}

install_swupd_packages() {
  if [[ ! "${swupd_packages}" ]]; then
    swupd_packages="$(curl -s -o - "${swupd_url}" | awk -F '"' '/-bin-|-lib-/{print $2}')"
  fi

  for key in "${@}"; do
    for pkg in $(echo "${swupd_packages}" | grep -F "${key}"); do
      curl -s -o - "${swupd_url}/${pkg}" | sudo bsdtar -xf - -C "/"
    done
  done
}

prepare_install_apt_packages() {
  local status="0"

  # sudo apt update -y
  sudo apt install -y "${@}" || status="${?}"

  if [[ "${status}" == "100" ]]; then
    prompt -w "\n  APT: Your repo lists might be broken"
    prompt -i "APT: Full-cleaning your repo lists and try again...\n"
    sudo apt clean -y; sudo rm -rf /var/lib/apt/lists
    sudo apt update -y; sudo apt install -y "${@}"
  fi
}

prepare_xbps() {
  [[ "${xbps_prepared}" == "true" ]] && return 0

  # 'xbps-install' requires 'xbps' to be always up-to-date
  sudo xbps-install -Syu xbps

  # System upgrading can't remove the old kernel files by it self. It eats the
  # boot partition and may cause kernel panic when there is no enough space
  sudo vkpurge rm all; sudo xbps-install -Syu

  xbps_prepared="true"
}

#-----------------Deps-----------------#

install_theme_deps() {
  if ! has_command sassc; then
    prompt -w "DEPS: 'sassc' are required for theme installation."
    prepare_deps

    if has_command zypper; then
      sudo zypper in -y sassc
    elif has_command swupd; then
      prepare_swupd && install_swupd_packages sassc libsass
    elif has_command apt; then
      prepare_install_apt_packages sassc
    elif has_command dnf; then
      sudo dnf install -y sassc
    elif has_command yum; then
      sudo yum install -y sassc
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed sassc
    elif has_command xbps-install; then
      prepare_xbps && sudo xbps-install -Sy sassc
    elif has_command eopkg; then
      sudo eopkg -y upgrade; sudo eopkg -y install sassc
    else
      installation_sorry
    fi
  fi

  if ! has_command glib-compile-resources; then
    prompt -w "DEPS: 'glib2.0' are required for theme installation."
    prepare_deps

    if has_command zypper; then
      sudo zypper in -y glib2-devel
    elif has_command swupd; then
      prepare_swupd && sudo swupd bundle-add libglib
    elif has_command apt; then
      prepare_install_apt_packages libglib2.0-dev-bin
    elif has_command dnf; then
      sudo dnf install -y glib2-devel
    elif has_command yum; then
      sudo yum install -y glib2-devel
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed glib2
    elif has_command xbps-install; then
      prepare_xbps && sudo xbps-install -Sy glib-devel
    elif has_command eopkg; then
      sudo eopkg -y upgrade; sudo eopkg -y install glib2
    else
      installation_sorry
    fi
  fi

  if ! has_command xmllint; then
    prompt -w "DEPS: 'xmllint' are required for theme installation."
    prepare_deps

    if has_command zypper; then
      sudo zypper in -y libxml2-tools
    elif has_command swupd; then
      prepare_swupd && sudo swupd bundle-add libxml2
    elif has_command apt; then
      prepare_install_apt_packages sassc libxml2-utils
    elif has_command dnf; then
      sudo dnf install -y libxml2
    elif has_command yum; then
      sudo yum install -y libxml2
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed libxml2
    elif has_command eopkg; then
      sudo eopkg -y upgrade; sudo eopkg -y install libxml2
    else
      installation_sorry
    fi
  fi
}

install_beggy_deps() {
  if ! has_command convert; then
    prompt -w "DEPS: 'imagemagick' is required for background editing."
    prepare_deps; stop_animation

    if has_command zypper; then
      sudo zypper in -y ImageMagick
    elif has_command swupd; then
      prepare_swupd && sudo swupd bundle-add ImageMagick
    elif has_command apt; then
      prepare_install_apt_packages imagemagick
    elif has_command dnf; then
      sudo dnf install -y ImageMagick
    elif has_command yum; then
      sudo yum install -y ImageMagick
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed imagemagick
    elif has_command xbps-install; then
      prepare_xbps && sudo xbps-install -Sy ImageMagick
    elif has_command eopkg; then
      sudo eopkg -y upgrade; sudo eopkg -y install imagemagick
    else
      installation_sorry
    fi
  fi
}

install_dialog_deps() {
  [[ "${silent_mode}" == "true" ]] && return 0

  if ! has_command dialog; then
    prompt -w "DEPS: 'dialog' is required for this option."
    prepare_deps

    if has_command zypper; then
      sudo zypper in -y dialog
    elif has_command swupd; then
      prepare_swupd && install_swupd_packages dialog
    elif has_command apt; then
      prepare_install_apt_packages dialog
    elif has_command dnf; then
      sudo dnf install -y dialog
    elif has_command yum; then
      sudo yum install -y dialog
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed dialog
    elif has_command xbps-install; then
      prepare_xbps && sudo xbps-install -Sy dialog
    elif has_command eopkg; then
      sudo eopkg -y upgrade; sudo eopkg -y install dialog
    else
      installation_sorry
    fi
  fi
}

install_flatpak_deps() {
  if ! has_command ostree || ! has_command appstream-compose; then
    prompt -w "DEPS: 'ostree' and 'appstream-util' is required for flatpak installing."
    prepare_deps; stop_animation

    if has_command zypper; then
      sudo zypper in -y libostree appstream-glib
    elif has_command swupd; then
      prepare_swupd && sudo swupd ostree libappstream-glib
    elif has_command apt; then
      prepare_install_apt_packages ostree appstream-util
    elif has_command dnf; then
      sudo dnf install -y ostree libappstream-glib
    elif has_command yum; then
      sudo yum install -y ostree libappstream-glib
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed ostree appstream-glib
    elif has_command xbps-install; then
      prepare_xbps && sudo xbps-install -Sy ostree appstream-glib
    elif has_command eopkg; then
      sudo eopkg -y upgrade; sudo eopkg -y ostree appstream-glib
    else
      installation_sorry
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
        install_beggy_deps
        convert "${background}" ${CONVERT_OPT}                                                "${WHITESUR_TMP_DIR}/beggy.png"
      else
        cp -r "${background}"                                                                 "${WHITESUR_TMP_DIR}/beggy.png"
      fi
      ;;
  esac
}

install_xfwmy() {
  local color="$(destify ${1})"

  local TARGET_DIR="${dest}/${name}${color}${colorscheme}"
  local HDPI_TARGET_DIR="${dest}/${name}${color}${colorscheme}-hdpi"
  local XHDPI_TARGET_DIR="${dest}/${name}${color}${colorscheme}-xhdpi"

  mkdir -p                                                                                    "${TARGET_DIR}/xfwm4"
  cp -r "${THEME_SRC_DIR}/assets/xfwm4/assets${color}${colorscheme}/"*".png"                  "${TARGET_DIR}/xfwm4"
  cp -r "${THEME_SRC_DIR}/main/xfwm4/themerc${color}"                                         "${TARGET_DIR}/xfwm4/themerc"

  mkdir -p                                                                                    "${HDPI_TARGET_DIR}/xfwm4"
  cp -r "${THEME_SRC_DIR}/assets/xfwm4/assets${color}${colorscheme}-hdpi/"*".png"             "${HDPI_TARGET_DIR}/xfwm4"
  cp -r "${THEME_SRC_DIR}/main/xfwm4/themerc${color}"                                         "${HDPI_TARGET_DIR}/xfwm4/themerc"

  mkdir -p                                                                                    "${XHDPI_TARGET_DIR}/xfwm4"
  cp -r "${THEME_SRC_DIR}/assets/xfwm4/assets${color}${colorscheme}-xhdpi/"*".png"            "${XHDPI_TARGET_DIR}/xfwm4"
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
    TARGET_DIR="${dest}/${name}${color}${opacity}${alt}${theme}${colorscheme}/gnome-shell"
  else
    TARGET_DIR="${6}"
  fi

  if [[ "${GNOME_VERSION}" == 'none' ]]; then
    local GNOME_VERSION='42-0'
  fi

  mkdir -p                                                                                    "${TARGET_DIR}"
  mkdir -p                                                                                    "${TARGET_DIR}/assets"
  cp -r "${THEME_SRC_DIR}/assets/gnome-shell/icons"                                           "${TARGET_DIR}"
  cp -r "${THEME_SRC_DIR}/main/gnome-shell/pad-osd.css"                                       "${TARGET_DIR}"
  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gnome-shell/shell-${GNOME_VERSION}/gnome-shell${color}.scss" "${TARGET_DIR}/gnome-shell.css"

  cp -r "${THEME_SRC_DIR}/assets/gnome-shell/common-assets/"*".svg"                           "${TARGET_DIR}/assets"
  cp -r "${THEME_SRC_DIR}/assets/gnome-shell/assets${color}/"*".svg"                          "${TARGET_DIR}/assets"
  cp -r "${THEME_SRC_DIR}/assets/gnome-shell/theme${theme}${colorscheme}/"*".svg"             "${TARGET_DIR}/assets"
  cp -r "${THEME_SRC_DIR}/assets/gnome-shell/activities/activities${icon}.svg"                "${TARGET_DIR}/assets/activities.svg"
  cp -r "${THEME_SRC_DIR}/assets/gnome-shell/activities/activities${icon}.svg"                "${TARGET_DIR}/assets/activities-white.svg"
  cp -r "${WHITESUR_TMP_DIR}/beggy.png"                                                       "${TARGET_DIR}/assets/background.png"

  (
    cd "${TARGET_DIR}"
    mv -f "assets/no-events.svg" "no-events.svg"
    mv -f "assets/process-working.svg" "process-working.svg"
    mv -f "assets/no-notifications.svg" "no-notifications.svg"
  )

  if [[ "${black_font:-}" == 'true' || "${opacity}" == '-solid' ]] && [[ "${color}" == '-Light' ]]; then
    cp -r "${THEME_SRC_DIR}/assets/gnome-shell/activities-black/activities${icon}.svg"        "${TARGET_DIR}/assets/activities.svg"
  fi
}

install_theemy() {
  local color="$(destify ${1})"
  local opacity="$(destify ${2})"
  local alt="$(destify ${3})"
  local theme="$(destify ${4})"

  if [[ "${color}" == '-Light' ]]; then
    local iconcolor=''
  elif [[ "${color}" == '-Dark' ]]; then
    local iconcolor='-Dark'
  fi

  local TARGET_DIR="${dest}/${name}${color}${opacity}${alt}${theme}${colorscheme}"
  local TMP_DIR_T="${WHITESUR_TMP_DIR}/gtk-3.0${color}${opacity}${alt}${theme}${colorscheme}"
  local TMP_DIR_F="${WHITESUR_TMP_DIR}/gtk-4.0${color}${opacity}${alt}${theme}${colorscheme}"

  mkdir -p                                                                                    "${TARGET_DIR}"

  local desktop_entry="[Desktop Entry]\n"
  desktop_entry+="Type=X-GNOME-Metatheme\n"
  desktop_entry+="Name=${name}${color}${opacity}${alt}${theme}${colorscheme}\n"
  desktop_entry+="Comment=A MacOS BigSur like Gtk+ theme based on Elegant Design\n"
  desktop_entry+="Encoding=UTF-8\n\n"

  desktop_entry+="[X-GNOME-Metatheme]\n"
  desktop_entry+="GtkTheme=${name}${color}${opacity}${alt}${theme}${colorscheme}\n"
  desktop_entry+="MetacityTheme=${name}${color}${opacity}${alt}${theme}${colorscheme}\n"
  desktop_entry+="IconTheme=${name}${iconcolor}\n"
  desktop_entry+="CursorTheme=WhiteSur-cursors\n"
  desktop_entry+="ButtonLayout=close,minimize,maximize:menu\n"

  echo -e "${desktop_entry}" >                                                                "${TARGET_DIR}/index.theme"

  #--------------------GTK-3.0--------------------#

  mkdir -p                                                                                    "${TMP_DIR_T}"
  cp -r "${THEME_SRC_DIR}/assets/gtk/common-assets/assets"                                    "${TMP_DIR_T}"
  cp -r "${THEME_SRC_DIR}/assets/gtk/common-assets/sidebar-assets/"*".png"                    "${TMP_DIR_T}/assets"
  cp -r "${THEME_SRC_DIR}/assets/gtk/scalable"                                                "${TMP_DIR_T}/assets"
  cp -r "${THEME_SRC_DIR}/assets/gtk/windows-assets/titlebutton${alt}${colorscheme}"          "${TMP_DIR_T}/windows-assets"

  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-3.0/gtk${color}.scss"                         "${TMP_DIR_T}/gtk.css"
  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-3.0/gtk-Dark.scss"                            "${TMP_DIR_T}/gtk-dark.css"

  mkdir -p                                                                                    "${TARGET_DIR}/gtk-3.0"
  cp -r "${THEME_SRC_DIR}/assets/gtk/thumbnails/thumbnail${color}${theme}${colorscheme}.png"  "${TARGET_DIR}/gtk-3.0/thumbnail.png"
  echo '@import url("resource:///org/gnome/theme/gtk.css");' >                                "${TARGET_DIR}/gtk-3.0/gtk.css"
  echo '@import url("resource:///org/gnome/theme/gtk-dark.css");' >                           "${TARGET_DIR}/gtk-3.0/gtk-dark.css"
  glib-compile-resources --sourcedir="${TMP_DIR_T}" --target="${TARGET_DIR}/gtk-3.0/gtk.gresource" "${THEME_SRC_DIR}/main/gtk-3.0/gtk.gresource.xml"

  #--------------------GTK-4.0--------------------#

  mkdir -p                                                                                    "${TMP_DIR_F}"
  cp -r "${TMP_DIR_T}/assets"                                                                 "${TMP_DIR_F}"
  cp -r "${TMP_DIR_T}/windows-assets"                                                         "${TMP_DIR_F}"

  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-4.0/gtk${color}.scss"                         "${TMP_DIR_F}/gtk.css"
  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-4.0/gtk-Dark.scss"                            "${TMP_DIR_F}/gtk-dark.css"

  mkdir -p                                                                                    "${TARGET_DIR}/gtk-4.0"
  cp -r "${THEME_SRC_DIR}/assets/gtk/thumbnails/thumbnail${color}${theme}${colorscheme}.png"  "${TARGET_DIR}/gtk-4.0/thumbnail.png"
  echo '@import url("resource:///org/gnome/theme/gtk.css");' >                                "${TARGET_DIR}/gtk-4.0/gtk.css"
  echo '@import url("resource:///org/gnome/theme/gtk-dark.css");' >                           "${TARGET_DIR}/gtk-4.0/gtk-dark.css"
  glib-compile-resources --sourcedir="${TMP_DIR_F}" --target="${TARGET_DIR}/gtk-4.0/gtk.gresource" "${THEME_SRC_DIR}/main/gtk-4.0/gtk.gresource.xml"

  #----------------Cinnamon-----------------#

  mkdir -p                                                                                    "${TARGET_DIR}/cinnamon"
  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/cinnamon/cinnamon${color}.scss"                   "${TARGET_DIR}/cinnamon/cinnamon.css"
  cp -r "${THEME_SRC_DIR}/assets/cinnamon/common-assets"                                      "${TARGET_DIR}/cinnamon/assets"
  cp -r "${THEME_SRC_DIR}/assets/cinnamon/assets${color}${colorscheme}/"*".svg"               "${TARGET_DIR}/cinnamon/assets"
  cp -r "${THEME_SRC_DIR}/assets/cinnamon/theme${theme}${colorscheme}/"*".svg"                "${TARGET_DIR}/cinnamon/assets"
  cp -r "${THEME_SRC_DIR}/assets/cinnamon/thumbnails/thumbnail${color}${theme}${colorscheme}.png" "${TARGET_DIR}/cinnamon/thumbnail.png"

  #----------------Misc------------------#

  mkdir -p                                                                                    "${TARGET_DIR}/gtk-2.0"
  cp -r "${THEME_SRC_DIR}/main/gtk-2.0/gtkrc${color}${theme}${colorscheme}"                   "${TARGET_DIR}/gtk-2.0/gtkrc"
  cp -r "${THEME_SRC_DIR}/main/gtk-2.0/menubar-toolbar${color}.rc"                            "${TARGET_DIR}/gtk-2.0/menubar-toolbar.rc"
  cp -r "${THEME_SRC_DIR}/main/gtk-2.0/common/"*".rc"                                         "${TARGET_DIR}/gtk-2.0"
  cp -r "${THEME_SRC_DIR}/assets/gtk-2.0/assets-common${color}${colorscheme}"                 "${TARGET_DIR}/gtk-2.0/assets"
  cp -r "${THEME_SRC_DIR}/assets/gtk-2.0/assets${color}${theme}${colorscheme}/"*".png"        "${TARGET_DIR}/gtk-2.0/assets"

  mkdir -p                                                                                    "${TARGET_DIR}/metacity-1"
  cp -r "${THEME_SRC_DIR}/main/metacity-1/metacity-theme${color}.xml"                         "${TARGET_DIR}/metacity-1/metacity-theme-1.xml"
  cp -r "${THEME_SRC_DIR}/main/metacity-1/metacity-theme-3.xml"                               "${TARGET_DIR}/metacity-1"
  cp -r "${THEME_SRC_DIR}/assets/metacity-1/titlebuttons${color}${colorscheme}"               "${TARGET_DIR}/metacity-1/titlebuttons"
  cp -r "${THEME_SRC_DIR}/assets/metacity-1/thumbnail${color}${colorscheme}.png"              "${TARGET_DIR}/metacity-1/thumbnail.png"
  ( cd "${TARGET_DIR}/metacity-1" && ln -s "metacity-theme-1.xml" "metacity-theme-2.xml" )

  mkdir -p                                                                                    "${TARGET_DIR}/plank"
  cp -r "${THEME_SRC_DIR}/other/plank/theme${color}/"*".theme"                                "${TARGET_DIR}/plank"
}

remove_packy() {
  rm -rf "${dest}/${name}$(destify ${1})$(destify ${2})$(destify ${3})$(destify ${4})${colorscheme}"
  rm -rf "${dest}/${name}$(destify ${1})${colorscheme}-hdpi"
  rm -rf "${dest}/${name}$(destify ${1})${colorscheme}-xhdpi"
}

remove_old_packy() {
  rm -rf "${dest}/${name}${1}$(destify ${2})$(destify ${3})$(destify ${4})${5}"
  rm -rf "${dest}/${name}${1}${5}-hdpi"
  rm -rf "${dest}/${name}${1}${5}-xhdpi"
}

###############################################################################
#                                 LIBADWAITA                                  #
###############################################################################

config_gtk4() {
  local color="$(destify ${1})"
  local alt="$(destify ${2})"

  local TARGET_DIR="${HOME}/.config/gtk-4.0"

  # Install gtk4.0 into config for libadwaita
  mkdir -p                                                                                    "${TARGET_DIR}"
  rm -rf                                                                                      "${TARGET_DIR}/"{gtk.css,gtk-dark.css,assets,windows-assets}
  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-4.0/gtk${color}.scss"                         "${TARGET_DIR}/gtk.css"
  sassc ${SASSC_OPT} "${THEME_SRC_DIR}/main/gtk-4.0/gtk-Dark.scss"                            "${TARGET_DIR}/gtk-dark.css"
  cp -r "${THEME_SRC_DIR}/assets/gtk/common-assets/assets"                                    "${TARGET_DIR}"
  cp -r "${THEME_SRC_DIR}/assets/gtk/common-assets/sidebar-assets/"*".png"                    "${TARGET_DIR}/assets"
  cp -r "${THEME_SRC_DIR}/assets/gtk/scalable"                                                "${TARGET_DIR}/assets"
  cp -r "${THEME_SRC_DIR}/assets/gtk/windows-assets/titlebutton${alt}${colorscheme}"          "${TARGET_DIR}/windows-assets"
}

install_libadwaita() {
  opacity="${opacities[0]}"
  color="${colors[1]}"

  gtk_base "${opacities[0]}" "${themes[0]}"
  config_gtk4 "${colors}" "${alts}"
}

remove_libadwaita() {
  rm -rf "${HOME}/.config/gtk-4.0/"{gtk.css,gtk-dark.css,assets,windows-assets}
}

###############################################################################
#                                   THEMES                                    #
###############################################################################

install_themes() {
  # "install_theemy" and "install_shelly" require "gtk_base", so multithreading
  # isn't possible

  install_theme_deps; start_animation; install_beggy

  for opacity in "${opacities[@]}"; do
    for alt in "${alts[@]}"; do
      for theme in "${themes[@]}"; do
        for color in "${colors[@]}"; do
          gtk_base "${opacity}" "${theme}" "${compact}"
          install_theemy "${color}" "${opacity}" "${alt}" "${theme}"
          install_shelly "${color}" "${opacity}" "${alt}" "${theme}" "${icon}"
          install_xfwmy "${color}"
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

  for color in '-light' '-dark'; do
    for opacity in "${OPACITY_VARIANTS[@]}"; do
      for alt in "${ALT_VARIANTS[@]}"; do
        for theme in "${THEME_VARIANTS[@]}"; do
          for scheme in '' '-nord'; do
            remove_old_packy "${color}" "${opacity}" "${alt}" "${theme}" "${scheme}"
          done
        done
      done
    done
  done

  wait ${process_ids[*]} &> /dev/null
}

install_gdm_theme() {
  local TARGET=

  # Let's go!
  install_theme_deps
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
    elif check_theme_file "$ZORIN_GR_FILE"; then
      TARGET="${ZORIN_GR_FILE}"
    elif check_theme_file "$MISC_GR_FILE"; then
      TARGET="${MISC_GR_FILE}"
    fi

    backup_file "${TARGET}"
    glib-compile-resources --sourcedir="${WHITESUR_TMP_DIR}/shelly" --target="${TARGET}" "${GS_GR_XML_FILE}"

    # Fix previously installed WhiteSur
    restore_file "${ETC_GR_FILE}"
  fi
}

revert_gdm_theme() {
  rm -rf "${WHITESUR_GS_DIR}"
  restore_file "${COMMON_CSS_FILE}"; restore_file "${UBUNTU_CSS_FILE}"
  restore_file "${ZORIN_CSS_FILE}"; restore_file "${ETC_CSS_FILE}"
  restore_file "${POP_OS_GR_FILE}"; restore_file "${YARU_GR_FILE}"
  restore_file "${MISC_GR_FILE}"; restore_file "${ETC_GR_FILE}"
  restore_file "${ZORIN_GR_FILE}"
}

###############################################################################
#                                  FIREFOX                                    #
###############################################################################

install_firefox_theme() {
  if has_snap_app firefox; then
    local TARGET_DIR="${FIREFOX_SNAP_THEME_DIR}"
  elif has_flatpak_app org.mozilla.firefox; then
    local TARGET_DIR="${FIREFOX_FLATPAK_THEME_DIR}"
  else
    local TARGET_DIR="${FIREFOX_THEME_DIR}"
  fi

  remove_firefox_theme
  udo mkdir -p                                                                                "${TARGET_DIR}"
  udo cp -rf "${FIREFOX_SRC_DIR}"/customChrome.css                                            "${TARGET_DIR}"

  if [[ "${monterey}" == 'true' ]]; then
    udo cp -rf "${FIREFOX_SRC_DIR}"/Monterey                                                  "${TARGET_DIR}"
    udo cp -rf "${FIREFOX_SRC_DIR}"/WhiteSur/{icons,titlebuttons}                             "${TARGET_DIR}"/Monterey
    if [[ "${alttheme}" == 'true' ]]; then
      udo cp -rf "${FIREFOX_SRC_DIR}"/userChrome-Monterey-alt.css                             "${TARGET_DIR}"/userChrome.css
    else
      udo cp -rf "${FIREFOX_SRC_DIR}"/userChrome-Monterey.css                                 "${TARGET_DIR}"/userChrome.css
    fi
  else
    udo cp -rf "${FIREFOX_SRC_DIR}"/WhiteSur                                                  "${TARGET_DIR}"
    udo cp -rf "${FIREFOX_SRC_DIR}"/userChrome-WhiteSur.css                                   "${TARGET_DIR}"/userChrome.css
  fi

  config_firefox
}

config_firefox() {
  # if has_snap_app firefox; then
  #   local TARGET_DIR="${FIREFOX_SNAP_THEME_DIR}"
  #   local FIREFOX_DIR="${FIREFOX_SNAP_DIR_HOME}"
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
      rm -rf                                                                                  "${d}/chrome"
      udo ln -sf "${TARGET_DIR}"                                                              "${d}/chrome"
      udoify_file                                                                             "${d}/prefs.js"
      echo "user_pref(\"toolkit.legacyUserProfileCustomizations.stylesheets\", true);" >>     "${d}/prefs.js"
      echo "user_pref(\"browser.tabs.drawInTitlebar\", true);" >>                             "${d}/prefs.js"
      echo "user_pref(\"browser.uidensity\", 0);" >>                                          "${d}/prefs.js"
      echo "user_pref(\"layers.acceleration.force-enabled\", true);" >>                       "${d}/prefs.js"
      echo "user_pref(\"mozilla.widget.use-argb-visuals\", true);" >>                         "${d}/prefs.js"
    fi
  done
}

edit_firefox_theme_prefs() {
  # if has_snap_app firefox; then
  #   local TARGET_DIR="${FIREFOX_SNAP_THEME_DIR}"
  if has_flatpak_app org.mozilla.firefox; then
    local TARGET_DIR="${FIREFOX_FLATPAK_THEME_DIR}"
  else
    local TARGET_DIR="${FIREFOX_THEME_DIR}"
  fi

  [[ ! -d "${TARGET_DIR}" ]] && install_firefox_theme ; config_firefox
  udo ${EDITOR:-nano}                                                                         "${TARGET_DIR}/userChrome.css"
  udo ${EDITOR:-nano}                                                                         "${TARGET_DIR}/customChrome.css"
}

remove_firefox_theme() {
  rm -rf "${FIREFOX_DIR_HOME}/"*"default"*"/chrome"
  rm -rf "${FIREFOX_THEME_DIR}"
  rm -rf "${FIREFOX_FLATPAK_DIR_HOME}/"*"default"*"/chrome"
  rm -rf "${FIREFOX_FLATPAK_THEME_DIR}"
  rm -rf "${FIREFOX_SNAP_DIR_HOME}/"*"default"*"/chrome"
  rm -rf "${FIREFOX_SNAP_THEME_DIR}"
}

###############################################################################
#                               DASH TO DOCK                                  #
###############################################################################

install_dash_to_dock() {
  if [[ -d "${DASH_TO_DOCK_DIR_HOME}" ]]; then
    backup_file "${DASH_TO_DOCK_DIR_HOME}" "udo"
    rm -rf "${DASH_TO_DOCK_DIR_HOME}"
  fi

  udo cp -rf "${DASH_TO_DOCK_SRC_DIR}/dash-to-dock@micxgx.gmail.com"   "${GNOME_SHELL_EXTENSION_DIR}"

  if has_command dbus-launch; then
    udo dbus-launch dconf write /org/gnome/shell/extensions/dash-to-dock/apply-custom-theme true
  fi
}

install_dash_to_dock_theme() {
  gtk_base "${colors[0]}" "${opacities[0]}" "${themes[0]}"

  if [[ -d "${DASH_TO_DOCK_DIR_HOME}" ]]; then
    backup_file "${DASH_TO_DOCK_DIR_HOME}/stylesheet.css" "udo"
    udoify_file                                                                                "${DASH_TO_DOCK_DIR_HOME}/stylesheet.css"
    if [[ "${GNOME_VERSION}" != '3-28'  ]]; then
      udo sassc ${SASSC_OPT} "${DASH_TO_DOCK_SRC_DIR}/stylesheet-4.scss"                       "${DASH_TO_DOCK_DIR_HOME}/stylesheet.css"
    else
      udo sassc ${SASSC_OPT} "${DASH_TO_DOCK_SRC_DIR}/stylesheet-3.scss"                      "${DASH_TO_DOCK_DIR_HOME}/stylesheet.css"
    fi
  elif [[ -d "${DASH_TO_DOCK_DIR_ROOT}" ]]; then
    backup_file "${DASH_TO_DOCK_DIR_ROOT}/stylesheet.css" "sudo"
    if [[ "${GNOME_VERSION}" != '3-28'  ]]; then
      sudo sassc ${SASSC_OPT} "${DASH_TO_DOCK_SRC_DIR}/stylesheet-4.scss"                      "${DASH_TO_DOCK_DIR_ROOT}/stylesheet.css"
    else
      sudo sassc ${SASSC_OPT} "${DASH_TO_DOCK_SRC_DIR}/stylesheet-3.scss"                      "${DASH_TO_DOCK_DIR_ROOT}/stylesheet.css"
    fi
  fi

  if has_command dbus-launch; then
    udo dbus-launch dconf write /org/gnome/shell/extensions/dash-to-dock/apply-custom-theme true
  fi
}

revert_dash_to_dock_theme() {
  if [[ -d "${DASH_TO_DOCK_DIR_HOME}" ]]; then
    restore_file "${DASH_TO_DOCK_DIR_HOME}/stylesheet.css" "udo"
  elif [[ -d "${DASH_TO_DOCK_DIR_ROOT}" ]]; then
    restore_file "${DASH_TO_DOCK_DIR_ROOT}/stylesheet.css" "sudo"
  fi

  if has_command dbus-launch; then
    udo dbus-launch dconf write /org/gnome/shell/extensions/dash-to-dock/apply-custom-theme false
  fi
}

###############################################################################
#                              FLATPAK & SNAP                                 #
###############################################################################

connect_flatpak() {
  install_flatpak_deps

  for opacity in "${opacities[@]}"; do
    for alt in "${alts[@]}"; do
      for theme in "${themes[@]}"; do
        for color in "${colors[@]}"; do
          pakitheme_gtk3 "${color}" "${opacity}" "${alt}" "${theme}"
        done
      done
    done
  done
}

disconnect_flatpak() {
  for opacity in "${opacities[@]}"; do
    for alt in "${alts[@]}"; do
      for theme in "${themes[@]}"; do
        for color in "${colors[@]}"; do
          flatpak_remove "${color}" "${opacity}" "${alt}" "${theme}"
        done
      done
    done
  done
}

#connect_snap() {
#  sudo snap install whitesur-gtk-theme

#  for i in $(snap connections | grep gtk-common-themes | awk '{print $2}' | cut -f1 -d: | sort -u); do
#    sudo snap connect "${i}:gtk-3-themes" "whitesur-gtk-theme:gtk-3-themes"
#    sudo snap connect "${i}:icon-themes" "whitesur-gtk-theme:icon-themes"
#  done
#}

#disconnect_snap() {
#  for i in $(snap connections | grep gtk-common-themes | awk '{print $2}' | cut -f1 -d: | sort -u); do
#    sudo snap disconnect "${i}:gtk-3-themes" "whitesur-gtk-theme:gtk-3-themes"
#    sudo snap disconnect "${i}:icon-themes" "whitesur-gtk-theme:icon-themes"
#  done
#}

#########################################################################
#                               GTK BASE                                #
#########################################################################

gtk_base() {
  cp -rf "${THEME_SRC_DIR}/sass/_gtk-base"{".scss","-temp.scss"}

  # Theme base options
  if [[ "${compact}" == 'false' ]]; then
    sed $SED_OPT "/\$laptop/s/true/false/"                                      "${THEME_SRC_DIR}/sass/_gtk-base-temp.scss"
  fi

  if [[ "${opacity}" == 'solid' ]]; then
    sed $SED_OPT "/\$trans/s/true/false/"                                       "${THEME_SRC_DIR}/sass/_gtk-base-temp.scss"
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

  # Darker dark colors
  if [[ "${colorscheme}" == '-nord' ]]; then
    prompt -s "Changing color scheme style to nord style ...\n"
    sed $SED_OPT "/\$colorscheme/s/default/nord/"                                "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Darker dark colors
  if [[ "${darker}" == 'true' ]]; then
    prompt -s "Changing dark color style to darker one ...\n"
    sed $SED_OPT "/\$darker/s/false/true/"                                      "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change Nautilus sidarbar size
  if [[ "${sidebar_size}" != 'default' ]]; then
    prompt -s "Changing Nautilus sidebar size ...\n"
    sed $SED_OPT "/\$sidebar_size/s/200px/${sidebar_size}px/"                   "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change Nautilus style
  if [[ "${nautilus_style}" != 'stable' ]]; then
    prompt -s "Changing Nautilus style ...\n"
    sed $SED_OPT "/\$nautilus_style/s/stable/${nautilus_style}/"                "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change Nautilus titlebutton placement style
  if [[ "${right_placement}" == 'true' ]]; then
    prompt -s "Changing Nautilus titlebutton placement style ...\n"
    sed $SED_OPT "/\$placement/s/left/right/"                                   "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change maximized window radius
  if [[ "${max_round}" == 'true' ]]; then
    prompt -s "Changing maximized window style ...\n"
    sed $SED_OPT "/\$max_window_style/s/square/round/"                          "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change gnome-shell panel transparency
  if [[ "${panel_opacity}" != 'default' ]]; then
    prompt -s "Changing panel transparency ...\n"
    sed $SED_OPT "/\$panel_opacity/s/0.15/0.${panel_opacity}/"                  "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change gnome-shell panel height size
  if [[ "${panel_size}" != 'default' ]]; then
    prompt -s "Changing panel height size to '${panel_size}'...\n"
    sed $SED_OPT "/\$panel_size/s/default/${panel_size}/"                       "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change gnome-shell show apps button style
  if [[ "${showapps_normal}" == 'true' ]]; then
    prompt -s "Changing gnome-shell show apps button style ...\n"
    sed $SED_OPT "/\$showapps_button/s/bigsur/normal/"                          "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change panel font color
  if [[ "${monterey}" == 'true' ]]; then
    black_font="true"
    prompt -s "Changing to Monterey style ...\n"
    sed $SED_OPT "/\$monterey/s/false/true/"                                    "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
    sed $SED_OPT "/\$panel_opacity/s/0.15/0.5/"                                 "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  # Change panel font color
  if [[ "${black_font}" == 'true' ]]; then
    prompt -s "Changing panel font color ...\n"
    sed $SED_OPT "/\$panel_font/s/white/black/"                                 "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi

  if [[ "${compact}" == 'false' ]]; then
    prompt -s "Changing Definition mode to HD (Bigger font, Bigger size) ..."
    #FIXME: @vince is it not implemented yet? (Only Gnome-shell and Gtk theme finished!)
  fi

  if [[ "${scale}" == 'x2' ]]; then
    prompt -s "Changing GDM scaling to 200% ...\n"
    sed $SED_OPT "/\$scale/s/default/x2/"                                       "${THEME_SRC_DIR}/sass/_theme-options-temp.scss"
  fi
}

#-----------------------------------DIALOGS------------------------------------#

# The default values here should get manually set and updated. Some of default
# values are taken from _variables.scss

show_panel_opacity_dialog() {
  install_dialog_deps
  dialogify panel_opacity "${THEME_NAME}" "Choose your panel opacity (Default is 15)" ${PANEL_OPACITY_VARIANTS[*]}
}

show_sidebar_size_dialog() {
  install_dialog_deps
  dialogify sidebar_size "${THEME_NAME}" "Choose your Nautilus minimum sidebar size (default is 200px)" ${SIDEBAR_SIZE_VARIANTS[*]}
}

show_nautilus_style_dialog() {
  install_dialog_deps
  dialogify nautilus_style "${THEME_NAME}" "Choose your Nautilus style (default is BigSur-like style)" ${NAUTILUS_STYLE_VARIANTS[*]}
}

show_needed_dialogs() {
  if [[ "${need_dialog["-p"]}" == "true" ]]; then show_panel_opacity_dialog; fi
  if [[ "${need_dialog["-s"]}" == "true" ]]; then show_sidebar_size_dialog; fi
  if [[ "${need_dialog["-N"]}" == "true" ]]; then show_nautilus_style_dialog; fi
}
