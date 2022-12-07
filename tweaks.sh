#! /usr/bin/env bash

# WARNING: Please make this shell not working-directory dependant, for example
# instead of using 'ls blabla', use 'ls "${REPO_DIR}/blabla"'
#
# WARNING: Don't use "cd" in this shell, use it in a subshell instead,
# for example ( cd blabla && do_blabla ) or $( cd .. && do_blabla )
#
# SUGGESTION: Please don't put any dependency installation here

###############################################################################
#                             VARIABLES & HELP                                #
###############################################################################

readonly REPO_DIR="$(dirname "$(readlink -m "${0}")")"
source "${REPO_DIR}/shell/lib-install.sh"

# Customization, default values
colors=("${COLOR_VARIANTS[@]}")
opacities=("${OPACITY_VARIANTS[@]}")

usage() {
  # Please specify their default value manually, some of them are come from _variables.scss
  # You also have to check and update them regurally
  helpify_title
  helpify "-g, --gdm"           "[default|x2]"                                      "Install '${THEME_NAME}' theme for GDM (scaling: 100%/200%, default is 100%)" "Requires to run this shell as root"
  helpify "-o, --opacity"       "[$(IFS='|'; echo "${OPACITY_VARIANTS[*]}")]"       "Set '${THEME_NAME}' GDM theme opacity variants"                              "Default is 'normal'"
  helpify "-c, --color"         "[$(IFS='|'; echo "${COLOR_VARIANTS[*]}")]"         "Set '${THEME_NAME}' GDM and Dash to Dock theme color variants"               "Default is 'light'"
  helpify "-t, --theme"         "[$(IFS='|'; echo "${THEME_VARIANTS[*]}")]"         "Set '${THEME_NAME}' GDM theme accent color"                                  "Default is BigSur-like theme"
  helpify "-N, --no-darken"     ""                                                  "Don't darken '${THEME_NAME}' GDM theme background image"                     ""
  helpify "-n, --no-blur"       ""                                                  "Don't blur '${THEME_NAME}' GDM theme background image"                       ""
  helpify "-b, --background"    "[default|blank|IMAGE_PATH]"                        "Set '${THEME_NAME}' GDM theme background image"                              "Default is BigSur-like wallpaper"
  helpify "-p, --panel-opacity" "[$(IFS='|'; echo "${PANEL_OPACITY_VARIANTS[*]}")]" "Set '${THEME_NAME}' GDM (GNOME Shell) theme panel transparency"              "Default is 15%"
  helpify "-P, --panel-size"    "[$(IFS='|'; echo "${PANEL_SIZE_VARIANTS[*]}")]"    "Set '${THEME_NAME}' Gnome shell panel height size"                           "Default is 32px"
  helpify "-i, --icon"          "[$(IFS='|'; echo "${ICON_VARIANTS[*]}")]"          "Set '${THEME_NAME}' GDM (GNOME Shell) 'Activities' icon"                     "Default is 'standard'"
  helpify "--nord, --nordcolor" ""                                                  "Install '${THEME_NAME}' Nord ColorScheme themes"                             ""

  helpify "-f, --firefox"       "[default|monterey|alt]"                            "Install '${THEME_NAME}|Monterey|Alt' theme for Firefox and connect it to the current Firefox profiles" "Default is ${THEME_NAME}"
  helpify "-e, --edit-firefox"  ""                                                  "Edit '${THEME_NAME}' theme for Firefox settings and also connect the theme to the current Firefox profiles" ""

  helpify "-F, --flatpak"       ""                                                  "Connect '${THEME_NAME}' theme to Flatpak"                                    ""
  #helpify "-s, --snap"          ""                                                  "Connect '${THEME_NAME}' theme the currently installed snap apps"             ""
  helpify "-d, --dash-to-dock"  ""                                                  "Fixed Dash to Dock theme issue"                                              ""

  helpify "-r, --remove, --revert" ""                                               "Revert to the original themes, do the opposite things of install and connect" ""
  helpify "--silent-mode"       ""                                                  "Meant for developers: ignore any confirm prompt and params become more strict" ""
  helpify "-h, --help"          ""                                                  "Show this help"                                                              ""
}

###############################################################################
#                                  MAIN                                       #
###############################################################################

#-----------------------------PARSE ARGUMENTS---------------------------------#

echo

while [[ $# -gt 0 ]]; do
  # Don't show any dialog here. Let this loop checks for errors or shows help
  # We can only show dialogs when there's no error and no -r parameter
  #
  # * shift for parameters that have no value
  # * shift 2 for parameter that have a value
  #
  # Please don't exit any error here if possible. Let it show all error warnings
  # at once

  case "${1}" in
      # Parameters that don't require value
    -r|--remove|--revert)
      uninstall='true'; shift ;;
    --silent-mode)
      full_sudo "${1}"; silent_mode='true'; shift ;;
    -h|--help)
      need_help="true"; shift ;;
    -f|--firefox|-e|--edit-firefox)
      case "${1}" in
        -f|--firefox)
          firefox="true" ;;
        -e|--edit-firefox)
          edit_firefox="true" ;;
      esac

      for variant in "${@}"; do
        case "${variant}" in
          default)
            shift 1
            ;;
          monterey)
            monterey="true"
            name="Monterey"
            shift 1
            ;;
          alt)
            monterey="true"
            alttheme="true"
            name="Monterey"
            shift 1
            ;;
        esac
      done

      if ! has_command firefox && ! has_command firefox-bin && ! has_flatpak_app org.mozilla.firefox && ! has_snap_app firefox && ! has_command firefox-developer-edition; then
        prompt -e "'${1}' ERROR: There's no Firefox installed in your system"
        has_any_error="true"
      elif [[ ! -d "${FIREFOX_DIR_HOME}" && ! -d "${FIREFOX_FLATPAK_DIR_HOME}" && ! -d "${FIREFOX_SNAP_DIR_HOME}" ]]; then
        prompt -e "'${1}' ERROR: Firefox is installed but not yet initialized."
        prompt -w "'${1}': Don't forget to close it after you run/initialize it"
        has_any_error="true"
      elif pidof "firefox" &> /dev/null || pidof "firefox-bin" &> /dev/null; then
        prompt -e "'${1}' ERROR: Firefox is running, please close it"
        has_any_error="true"
      fi; shift ;;
    -F|--flatpak)
      flatpak="true"; signal_exit

      if ! has_command flatpak; then
        prompt -e "'${1}' ERROR: There's no Flatpak installed in your system"
        has_any_error="true"
      fi; shift ;;
#    -s|--snap)
#      snap="true";

#      if ! has_command snap; then
#        prompt -e "'${1}' ERROR: There's no Snap installed in your system"
#        has_any_error="true"
#      fi; shift ;;
    -g|--gdm)
      gdm="true"; full_sudo "${1}"
      showapps_normal="true" # use normal showapps icon
      background="default"

      for variant in "${@}"; do
        case "${variant}" in
          default)
            shift 1
            ;;
          x2)
            scale="x2"
            shift 1
            ;;
        esac
      done

      if ! has_command gdm && ! has_command gdm3 && [[ ! -e /usr/sbin/gdm3 ]]; then
        prompt -e "'${1}' ERROR: There's no GDM installed in your system"
        has_any_error="true"
      fi; shift ;;
    -d|--dash-to-dock)
      if [[ ! -d "${DASH_TO_DOCK_DIR_HOME}" && ! -d "${DASH_TO_DOCK_DIR_ROOT}" ]]; then
        prompt -e "'${1}' ERROR: There's no Dash to Dock installed in your system"
        has_any_error="true"
      else
        dash_to_dock="true"
      fi; shift ;;
    -N|--no-darken)
      no_darken="true"; shift ;;
    -n|--no-blur)
      no_blur="true"; shift ;;
    -l|--libadwaita)
      libadwaita="true"; shift ;;
      # Parameters that require value, single use
    -b|--background)
      check_param "${1}" "${1}" "${2}" "must" "must" "must" "false" && shift 2 || shift ;;
    -i|--icon)
      check_param "${1}" "${1}" "${2}" "must" "must" "must" "false" && shift 2 || shift ;;
    -p|--panel-opacity)
      check_param "${1}" "${1}" "${2}" "optional" "optional" "optional" && shift 2 || shift ;;
    -P|--panel-size)
      check_param "${1}" "${1}" "${2}" "optional" "optional" "optional" && shift 2 || shift ;;
    -o|--opacity)
      check_param "${1}" "${1}" "${2}" "must" "must" "must" "false" && shift 2 || shift ;;
    -c|--color)
      check_param "${1}" "${1}" "${2}" "must" "must" "must" "false" && shift 2 || shift ;;
    -t|--theme)
      check_param "${1}" "${1}" "${2}" "must" "must" "must" "false" && shift 2 || shift ;;
    *)
      prompt -e "ERROR: Unrecognized tweak option '${1}'."
      has_any_error="true"; shift ;;
  esac
done

finalize_argument_parsing

#---------------------------START INSTALL THEMES-------------------------------#

if [[ "${uninstall}" == 'true' ]]; then
  prompt -w "REMOVAL: Non file-related parameters will be ignored. \n"

#  if [[ "${snap}" == 'true' ]]; then
#    prompt -i "Disconnecting '${name}' theme from your installed snap apps... \n"
#    disconnect_snap
#    prompt -s "Done! '${name}' theme has been disconnected from your snap apps."; echo
#  fi

  if [[ "${flatpak}" == 'true' ]]; then
    prompt -i "Disconnecting '${name}' theme from your Flatpak... \n"
    disconnect_flatpak
    prompt -s "Done! '${name}' theme has been disconnected from your Flatpak."; echo
  fi

  if [[ "${gdm}" == 'true' ]]; then
    prompt -i "Removing '${name}' GDM theme... \n"
    revert_gdm_theme
    prompt -s "Done! '${name}' GDM theme has been removed."; echo
  fi

  if [[ "${dash_to_dock}" == 'true' ]]; then
    prompt -i "Removing '${name}' Dash to Dock theme... \n"
    revert_dash_to_dock_theme
    prompt -s "Done! '${name}' Dash to Dock theme has been removed."; echo
  fi

  if [[ "${firefox}" == 'true' ]]; then
    prompt -i "Removing '${name}' Firefox theme... \n"
    remove_firefox_theme
    prompt -s "Done! '${name}' Firefox theme has been removed."; echo
  fi
else
  show_needed_dialogs; customize_theme

  if [[ "${snap}" == 'true' ]]; then
    prompt -i "Connecting '${name}' theme to your installed snap apps... \n"
    connect_snap
    prompt -s "Done! '${name}' theme has been connected to your snap apps."; echo
  fi

  if [[ "${flatpak}" == 'true' ]]; then
    prompt -i "Connecting '${name}' themes to your Flatpak... \n"
    connect_flatpak
    prompt -s "Done! '${name}' theme has been connected to your Flatpak."; echo
  fi

  if [[ "${gdm}" == 'true' ]]; then
    prompt -i "Installing '${name}' GDM theme... \n"
    install_gdm_theme
    prompt -s "Done! '${name}' GDM theme has been installed."; echo
  fi

  if [[ "${dash_to_dock}" == 'true' ]]; then
    prompt -i "Installing '${name}' ${colors[0]} Dash to Dock theme... \n"
    install_dash_to_dock_theme
    prompt -s "Done! '${name}' Dash to Dock theme has been installed. \n"
    prompt -w "DASH TO DOCK: You may need to logout to take effect. \n"
  fi

  if [[ "${firefox}" == 'true' || "${edit_firefox}" == 'true' ]]; then
    if [[ "${firefox}" == 'true' ]]; then
      prompt -i "Installing '${name}' Firefox theme... \n"
      install_firefox_theme
      prompt -s "Done! '${name}' Firefox theme has been installed."; echo
    fi

    if [[ "${edit_firefox}" == 'true' ]]; then
      prompt -i "Editing '${name}' Firefox theme preferences... \n"
      edit_firefox_theme_prefs
      prompt -s "Done! '${name}' Firefox theme preferences has been edited."; echo
    fi

    prompt -w "FIREFOX: Please go to [Firefox menu] > [Customize...], and customize your Firefox to make it work. Move your 'new tab' button to the titlebar instead of tab-switcher."
    prompt -i "FIREFOX: Anyways, you can also edit 'userChrome.css' and 'customChrome.css' later in your Firefox profile directory."
    echo
  fi
fi

if [[ "${firefox}" == "false" && "${edit_firefox}" == "false" && "${flatpak}" == "false" && "${gdm}" == "false" && "${dash_to_dock}" == "false" && "${libadwaita}" == "false" ]]; then
  prompt -e "Oops... there's nothing to tweak..."
  prompt -i "HINT: Don't forget to define which component to tweak, e.g. '--gdm'"
  prompt -i "HINT: Run ./tweaks.sh -h for help!..."; echo
fi
