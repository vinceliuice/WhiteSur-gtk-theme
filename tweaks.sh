#! /bin/bash

# WARNING: Please make this shell not working-directory dependant, for example
# instead of using 'cd blabla', use 'cd "${REPO_DIR}/blabla"'
#
# WARNING: Please don't use sudo directly here since it steals our EXIT trap
#
# WARNING: Don't use "cd" in this shell, use it in a subshell instead,
# for example ( cd blabla && do_blabla ) or $( cd .. && do_blabla )

###############################################################################
#                             VARIABLES & HELP                                #
###############################################################################

readonly REPO_DIR="$(dirname "$(readlink -m "${0}")")"
source "${REPO_DIR}/lib-install.sh"

usage() {
  # Please specify their default value manually, some of them are come from _variables.scss
  # You also have to check and update them regurally
  helpify_title
  helpify "-f, --firefox"      ""                                                  "Install '${THEME_NAME}' theme for Firefox and connect it to the current Firefox profiles" ""
  helpify "-e, --edit-firefox" ""                                                  "Edit '${THEME_NAME}' theme for Firefox settings and also connect the theme to the current Firefox profiles" ""
  helpify "-F, --flatpak"      ""                                                  "Connect '${THEME_NAME}' theme to Flatpak"                                    ""
  helpify "-s, --snap"         ""                                                  "Connect '${THEME_NAME}' theme the currently installed snap apps"             ""
  helpify "-g, --gdm"          ""                                                  "Install '${THEME_NAME}' theme for GDM"                                       "Requires to run this shell as root"
  helpify "-d, --dash-to-dock" ""                                                  "Install '${THEME_NAME}' theme for Dash to Dock and connect it to the current Dash to Dock installation(s)" ""
  helpify "-D, --darken"       ""                                                  "Darken '${THEME_NAME}' GDM theme background image"                           ""
  helpify "-n, --no-blur"      ""                                                  "Don't blur '${THEME_NAME}' GDM theme background image"                       ""
  helpify "-b, --background"   "[default|blank|IMAGE_PATH]"                        "Set '${THEME_NAME}' GDM theme background image"                              "Default is BigSur-like wallpaper"
  helpify "-o, --opacity"      "[$(IFS='|'; echo "${OPACITY_VARIANTS[*]}")]"       "Set '${THEME_NAME}' GDM theme opacity variants"                              "Default is 'normal'"
  helpify "-c, --color"        "[$(IFS='|'; echo "${COLOR_VARIANTS[*]}")]"         "Set '${THEME_NAME}' GDM and Dash to Dock theme color variants"               "Default is 'light'"
  helpify "-t, --theme"        "[$(IFS='|'; echo "${THEME_VARIANTS[*]}")]"         "Set '${THEME_NAME}' GDM theme accent color"                                  "Default is BigSur-like theme"
  helpify "-p, --panel"        "[$(IFS='|'; echo "${PANEL_OPACITY_VARIANTS[*]}")]" "Set '${THEME_NAME}' GDM (GNOME Shell) theme panel transparency"              "Default is 15%"
  helpify "-i, --icon"         "[$(IFS='|'; echo "${ICON_VARIANTS[*]}")]"          "Set '${THEME_NAME}' GDM (GNOME Shell) 'Activities' icon"                     "Default is 'standard'"
  helpify "-r, --remove, --revert" ""                                              "Revert to the original themes, do the opposite things of install and connect" ""
  helpify "-h, --help"         ""                                                  "Show this help"                                                              ""
}

###############################################################################
#                                  MAIN                                       #
###############################################################################

#-----------------------------PARSE ARGUMENTS---------------------------------#

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
    -h|--help)
      need_help="true"; shift ;;
    -f|--firefox|-e|--edit-firefox)
      case "${1}" in
        -f|--firefox)
          firefox="true" ;;
        -e|--edit-firefox)
          edit_firefox="true" ;;
      esac

      if ! has_command firefox; then
        prompt -e "'${1}' ERROR: There's no Firefox installed in your system"
        has_any_error="true"
      elif [[ ! -d "${FIREFOX_DIR_HOME}" ]]; then
        prompt -e "'${1}' ERROR: Firefox is installed but not yet initialized."
        prompt -w "'${1}': Don't forget to close it after you run/initialize it"
        has_any_error="true"
      elif pidof "firefox" &> /dev/null; then
        prompt -e "'${1}' ERROR: Firefox is running, please close it"
        has_any_error="true"
      fi; shift ;;
    -F|--flatpak)
      flatpak="true";

      if ! has_command flatpak; then
        prompt -e "'${1}' ERROR: There's no Flatpak installed in your system"
        has_any_error="true"
      fi; shift ;;
    -s|--snap)
      snap="true";

      if ! has_command snap; then
        prompt -e "'${1}' ERROR: There's no Snap installed in your system"
        has_any_error="true"
      fi; shift ;;
    -g|--gdm)
      gdm="true"; full_rootify "${1}"

      if ! has_command gdm && ! has_command gdm3; then
        prompt -e "'${1}' ERROR: There's no GDM installed in your system"
        has_any_error="true"
      fi; shift ;;
    -d|--dash-to-dock)
      if [[ "${GNOME_VERSION}" == 'new'  ]]; then
        prompt -e "'${1}' ERROR: There's no need to install on >= Gnome 40.0!"
        has_any_error="true"
      else
        dash_to_dock="true"
      fi
      if [[ ! -d "${DASH_TO_DOCK_DIR_HOME}" && ! -d "${DASH_TO_DOCK_DIR_ROOT}" ]]; then
        prompt -e "'${1}' ERROR: There's no Dash to Dock installed in your system"
        has_any_error="true"
      fi; shift ;;
    -D|--darken)
      darken="true"; shift ;;
    -n|--no-blur)
      no_blur="true"; shift ;;
    # Parameters that require value, single use
    -b|--background)
      check_param "${1}" "${1}" "${2}" "must" "must" "must" "false" && shift 2 || shift ;;
    -i|--icon)
      check_param "${1}" "${1}" "${2}" "must" "must" "must" "false" && shift 2 || shift ;;
    -p|--panel)
      check_param "${1}" "${1}" "${2}" "must" "optional" "optional" "false" && shift 2 || shift ;;
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
  echo; prompt -w "REMOVAL: Non file-related parameters will be ignored."

  if [[ "${gdm}" == 'true' ]]; then
    echo; prompt -i "Removing '${name}' GDM theme..."
    revert_gdm_theme
    echo; prompt -s "Done! '${name}' GDM theme has been removed."
  fi

  if [[ "${dash_to_dock}" == 'true' ]]; then
    echo; prompt -i "Removing '${name}' Dash to Dock theme..."
    revert_dash_to_dock_theme
    echo; prompt -s "Done! '${name}' Dash to Dock theme has been removed."
  fi

  if [[ "${firefox}" == 'true' ]]; then
    echo; prompt -i "Removing '${name}' Firefox theme..."
    remove_firefox_theme
    echo; prompt -s "Done! '${name}' Firefox theme has been removed."
  fi

  if [[ "${snap}" == 'true' ]]; then
    echo; prompt -i "Disconnecting '${name}' theme from your installed snap apps..."
    disconnect_snap
    echo; prompt -s "Done! '${name}' theme has been disconnected from your snap apps."
  fi

  if [[ "${flatpak}" == 'true' ]]; then
    echo; prompt -i "Disconnecting '${name}' theme from your Flatpak..."
    disconnect_flatpak
    echo; prompt -s "Done! '${name}' theme has been disconnected from your Flatpak."
  fi
else
  show_needed_dialogs; customize_theme

  if [[ "${gdm}" == 'true' ]]; then
    echo; prompt -i "Installing '${name}' GDM theme..."
    install_gdm_deps; install_gdm_theme
    echo; prompt -s "Done! '${name}' GDM theme has been installed."
  fi

  if [[ "${dash_to_dock}" == 'true' ]]; then
    echo; prompt -i "Installing '${name}' ${colors[0]} Dash to Dock theme..."
    install_dash_to_dock_theme
    echo; prompt -s "Done! '${name}' Dash to Dock theme has been installed."
    prompt -w "DASH TO DOCK: You may need to logout to take effect."
  fi

  if [[ "${firefox}" == 'true' || "${edit_firefox}" == 'true' ]]; then
    if [[ "${firefox}" == 'true' ]]; then
      echo; prompt -i "Installing '${name}' Firefox theme..."
      install_firefox_theme
      echo; prompt -s "Done! '${name}' Firefox theme has been installed."
    fi

    if [[ "${edit_firefox}" == 'true' ]]; then
      echo; prompt -i "Editing '${name}' Firefox theme preferences..."
      edit_firefox_theme_prefs
      echo; prompt -s "Done! '${name}' Firefox theme preferences has been edited."
    fi

    echo
    prompt -w "FIREFOX: Please go to [Firefox menu] > [Customize...], and customize your Firefox to make it work. Move your 'new tab' button to the titlebar instead of tab-switcher."
    prompt -w "FIREFOX: Anyways, you can also edit 'userChrome.css' and 'customChrome.css' later in '${FIREFOX_THEME_DIR}'."
  fi

  if [[ "${snap}" == 'true' ]]; then
    echo; prompt -i "Connecting '${name}' theme to your installed snap apps..."
    connect_snap
    echo; prompt -s "Done! '${name}' theme has been connected to your snap apps."
  fi

  if [[ "${flatpak}" == 'true' ]]; then
    echo; prompt -i "Connecting '${name}' theme to your Flatpak..."
    connect_flatpak
    echo; prompt -s "Done! '${name}' theme has been connected to your Flatpak."
  fi
fi

if [[ "${firefox}" == "false" && "${edit_firefox}" == "false" && "${flatpak}" == "false" && "${snap}" == "false" && "${gdm}" == "false" && "${dash_to_dock}" == "false" ]]; then
  echo; prompt -e "Oops... there's nothing to tweaks..."
  echo; prompt -i "Run ./tweaks.sh -h for help!..."
fi

echo
