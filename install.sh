#! /usr/bin/env bash

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

# Customization, default values
colors=("${COLOR_VARIANTS[@]}")
opacities=("${OPACITY_VARIANTS[@]}")
background="blank"

usage() {
  # Please specify their default value manually, some of them are come from _variables.scss
  # You also have to check and update them regurally
  helpify_title
  helpify "-d, --dest"           "DIR"                                                "Set destination directory"                        "Default is '${THEME_DIR}'"
  helpify "-n, --name"           "NAME"                                               "Set theme name"                                   "Default is '${THEME_NAME}'"
  helpify "-o, --opacity"        "[$(IFS='|'; echo "${OPACITY_VARIANTS[*]}")]"        "Set theme opacity variants"                       "Repeatable. Default is all variants"
  helpify "-c, --color"          "[$(IFS='|'; echo "${COLOR_VARIANTS[*]}")]"          "Set theme color variants"                         "Repeatable. Default is all variants"
  helpify "-a, --alt"            "[$(IFS='|'; echo "${ALT_VARIANTS[*]}")|all]"        "Set window control buttons variant"               "Repeatable. Default is 'normal'"
  helpify "-t, --theme"          "[$(IFS='|'; echo "${THEME_VARIANTS[*]}")|all]"      "Set theme accent color"                           "Repeatable. Default is BigSur-like theme"
  helpify "-p, --panel"          "[$(IFS='|'; echo "${PANEL_OPACITY_VARIANTS[*]}")]"  "Set panel transparency"                           "Default is 15%"
  helpify "-s, --size"           "[$(IFS='|'; echo "${SIDEBAR_SIZE_VARIANTS[*]}")]"   "Set Nautilus sidebar minimum width"               "Default is 200px"
  helpify "-i, --icon"           "[$(IFS='|'; echo "${ICON_VARIANTS[*]}")]"           "Set 'Activities' icon"                            "Default is 'standard'"
  helpify "-b, --background"     "[default|blank|IMAGE_PATH]"                         "Set gnome-shell background image"                 "Default is BigSur-like wallpaper"
  helpify "-N, --nautilus-style" "[$(IFS='|'; echo "${NAUTILUS_STYLE_VARIANTS[*]}")]" "Set Nautilus style"                               "Default is BigSur-like style"
  helpify "--round, --roundedmaxwindow"   ""                                          "Set maximized window to rounded"                  "Default is square"
  helpify "--right, --rightplacement"     ""                                          "Set Nautilus titlebutton placement style to right" "Default is left"
  helpify "--normal, --normalshowapps"    ""                                          "Set gnome-shell show apps button style to normal" "Default is bigsur"
  helpify "--dialog, --interactive"       ""                                          "Run this installer interactively, with dialogs"   ""
  helpify "-r, --remove, -u, --uninstall" ""                                          "Remove all installed ${THEME_NAME} themes"        ""
  helpify "-h, --help"                    ""                                          "Show this help"                                   ""
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
    -r|--remove|-u|-uninstall)
      uninstall='true'; shift ;;
    --dialog|--interactive)
      interactive='true'; shift ;;
    --normal|--normalshowapps)
      showapps_normal="true"; shift ;;
    --right|--rightplacement)
      right_placement="true"; shift ;;
    --round|--roundedmaxwindow)
      max_round="true"; shift ;;
    -h|--help)
      need_help="true"; shift ;;
      # Parameters that require value, single use
    -b|--background)
      check_param "${1}" "${1}" "${2}" "must" "must" "must" "false" && shift 2 || shift ;;
    -d|--dest)
      check_param "${1}" "${1}" "${2}" "must" "must" "not-at-all" && shift 2 || shift ;;
    -n|--name)
      check_param "${1}" "${1}" "${2}" "must" "must" "not-at-all" && shift 2 || shift ;;
    -i|--icon)
      check_param "${1}" "${1}" "${2}" "must" "must" "must" && shift 2 || shift ;;
    -s|--size)
      check_param "${1}" "${1}" "${2}" "optional" "optional" "optional" && shift 2 || shift ;;
    -p|--panel)
      check_param "${1}" "${1}" "${2}" "optional" "optional" "optional" && shift 2 || shift ;;
    -N|--nautilus-style)
      check_param "${1}" "${1}" "${2}" "optional" "optional" "optional" && shift 2 || shift ;;
      # Parameters that require value, multiple use
    -a|--alt)
      check_param "${1}" "${1}" "${2}" "not-at-all" "must" "must" && shift 2 || shift ;;
    -o|--opacity)
      check_param "${1}" "${1}" "${2}" "not-at-all" "must" "must" && shift 2 || shift ;;
    -c|--color)
      check_param "${1}" "${1}" "${2}" "not-at-all" "must" "must" && shift 2 || shift ;;
    -t|--theme)
      check_param "${1}" "${1}" "${2}" "not-at-all" "must" "must" && shift 2 || shift ;;
    *)
      prompt -e "ERROR: Unrecognized installation option '${1}'."
      has_any_error="true"; shift ;;
  esac
done

finalize_argument_parsing

#---------------------------START INSTALL THEMES-------------------------------#

if [[ "${uninstall}" == 'true' ]]; then
  prompt -i "Removing '${name}' themes in '${dest}'..."
  prompt -w "REMOVAL: Non file-related parameters will be ignored."; echo
  remove_themes
  prompt -s "Done! All '${name}' themes has been removed."
else
  install_theme_deps; echo

  if [[ "${interactive}" == 'true' ]]; then
    show_panel_opacity_dialog; show_sidebar_size_dialog; show_nautilus_style_dialog
    prompt -w "DIALOG: '--size' and '--panel' parameters are ignored if exist."; echo
  else show_needed_dialogs; fi

  prompt -w "Removing the old '${name}' themes..."

  remove_themes; customize_theme; avoid_variant_duplicates; echo

  prompt -i "Installing '${name}' themes in '${dest}'..."
  prompt -i "--->>> GTK | GNOME Shell | Cinnamon | Metacity | XFWM | Plank <<<---"
  prompt -i "Color variants   : $( IFS=';'; echo "${colors[*]}" )"
  prompt -i "Theme variants   : $( IFS=';'; echo "${themes[*]}" )"
  prompt -i "Opacity variants : $( IFS=';'; echo "${opacities[*]}" )"
  prompt -i "Alt variants     : $( IFS=';'; echo "${alts[*]}" )"
  prompt -i "Icon variant     : ${icon}"
  prompt -i "Nautilus variant : ${nautilus_style}"

  echo; install_themes; echo; prompt -s "Done!"

  # rm -rf "${THEME_SRC_DIR}/sass/_gtk-base-temp.scss"

  if is_my_distro "arch" && has_command xfce4-session; then
    msg="XFCE: you may need to logout after changing your theme to fix your panel opacity."
    notif_msg="${msg}\n\n${final_msg}"

    echo; prompt -w "${msg}"
  else
    notif_msg="${final_msg}"
  fi

  echo; prompt -w "${final_msg}"; echo

  [[ -x /usr/bin/notify-send ]] && notify-send "'${name}' theme has been installed. Enjoy!" "${notif_msg}" -i "dialog-information-symbolic"
fi
