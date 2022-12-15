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
  helpify "-d, --dest"           "DIR"                                                "Set destination directory"                        "Default is '${THEME_DIR}'"
  helpify "-n, --name"           "NAME"                                               "Set theme name"                                   "Default is '${THEME_NAME}'"
  helpify "-o, --opacity"        "[$(IFS='|'; echo "${OPACITY_VARIANTS[*]}")]"        "Set theme opacity variants"                       "Repeatable. Default is all variants"
  helpify "-c, --color"          "[$(IFS='|'; echo "${COLOR_VARIANTS[*]}")]"          "Set theme color variants"                         "Repeatable. Default is all variants"
  helpify "-a, --alt"            "[$(IFS='|'; echo "${ALT_VARIANTS[*]}")|all]"        "Set window control buttons variant"               "Repeatable. Default is 'normal'"
  helpify "-t, --theme"          "[$(IFS='|'; echo "${THEME_VARIANTS[*]}")|all]"      "Set theme accent color"                           "Repeatable. Default is BigSur-like theme"
  helpify "-p, --panel-opacity"  "[$(IFS='|'; echo "${PANEL_OPACITY_VARIANTS[*]}")]"  "Set panel transparency"                           "Default is 15%"
  helpify "-P, --panel-size"     "[$(IFS='|'; echo "${PANEL_SIZE_VARIANTS[*]}")]"     "Set Gnome shell panel height size"                "Default is 32px"
  helpify "-s, --size"           "[$(IFS='|'; echo "${SIDEBAR_SIZE_VARIANTS[*]}")]"   "Set Nautilus sidebar minimum width"               "Default is 200px"
  helpify "-i, --icon"           "[$(IFS='|'; echo "${ICON_VARIANTS[*]}")]"           "Set 'Activities' icon"                            "Default is 'standard'"
  helpify "-b, --background"     "[default|blank|IMAGE_PATH]"                         "Set gnome-shell background image"                 "Default is BigSur-like wallpaper"
  helpify "-m, --monterey"                ""                                          "Set to MacOS Monterey style"                      ""
  helpify "-N, --nautilus-style" "[$(IFS='|'; echo "${NAUTILUS_STYLE_VARIANTS[*]}")]" "Set Nautilus style"                               "Default is BigSur-like style (stabled sidebar)"
  helpify "-l, --libadwaita"              ""                                          "Install theme into gtk4.0 config for libadwaita"  "Default is dark version"
  helpify "-HD, --highdefinition"         ""                                          "Set to High Definition size"                      "Default is laptop size"
  helpify "--normal, --normalshowapps"    ""                                          "Set gnome-shell show apps button style to normal" "Default is bigsur"
  helpify "--round, --roundedmaxwindow"   ""                                          "Set maximized window to rounded"                  "Default is square"
  helpify "--right, --rightplacement"     ""                                          "Set Nautilus titlebutton placement to right"      "Default is left"
  helpify "--black, --blackfont"          ""                                          "Set panel font color to black"                    "Default is white"
  helpify "--darker, --darkercolor"       ""                                          "Install darker '${THEME_NAME}' dark themes"       ""
  helpify "--nord, --nordcolor"           ""                                          "Install '${THEME_NAME}' Nord ColorScheme themes"  ""
  helpify "--dialog, --interactive"       ""                                          "Run this installer interactively, with dialogs"   ""
  helpify "--silent-mode"                 ""                                          "Meant for developers: ignore any confirm prompt and params become more strict" ""
  helpify "-r, --remove, -u, --uninstall" ""                                          "Remove all installed ${THEME_NAME} themes"        ""
  helpify "-h, --help"                    ""                                          "Show this help"                                   ""
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
    -r|--remove|-u|-uninstall)
      uninstall='true'; shift ;;
    --silent-mode)
      full_sudo "${1}"; silent_mode='true'; shift ;;
    --dialog|--interactive)
      interactive='true'; shift ;;
    --normal|--normalshowapps)
      showapps_normal="true"; shift ;;
    --right|--rightplacement)
      right_placement="true"; shift ;;
    --round|--roundedmaxwindow)
      max_round="true"; shift ;;
    --black|--blackfont)
      black_font="true"; shift ;;
    --darker|--darkercolor)
      darker="true"; shift ;;
    --nord|--nordcolor)
      colorscheme="-nord"; shift ;;
    -HD|--highdefinition)
      compact="false"; shift ;;
    -m|--monterey)
      monterey="true"; shift ;;
    -l|--libadwaita)
      libadwaita="true"; shift ;;
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
    -p|--panel-opacity)
      check_param "${1}" "${1}" "${2}" "optional" "optional" "optional" && shift 2 || shift ;;
    -P|--panel-size)
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
    -h|--help)
      need_help="true"; shift ;;
    *)
      prompt -e "ERROR: Unrecognized installation option '${1}'."
      has_any_error="true"; shift ;;
  esac
done

finalize_argument_parsing

#---------------------------START INSTALL THEMES-------------------------------#

if [[ "${uninstall}" == 'true' ]]; then
  if [[ "${libadwaita}" == 'true' ]]; then
    if [[ "$UID" != '0' ]]; then
      remove_libadwaita
      prompt -s "Removed gtk-4.0 theme files in '${HOME}/.config/gtk-4.0/' !"; echo
    else
      prompt -e "Do not run '--libadwaita' option with sudo!"; echo
    fi
  else
    prompt -i "Removing '${name}' gtk themes in '${dest}'... \n"
    prompt -w "REMOVAL: Non file-related parameters will be ignored. \n"
    remove_themes; remove_libadwaita
    prompt -s "Done! All '${name}' gtk themes in has been removed."
  fi

  if [[ -f "${MISC_GR_FILE}.bak" ]]; then
    prompt -e "Find installed GDM theme, you need to run: 'sudo ./tweaks.sh -g -r' to remove it!"
  fi
else
  if [[ "${interactive}" == 'true' ]]; then
    show_panel_opacity_dialog; show_sidebar_size_dialog; show_nautilus_style_dialog
    echo; prompt -w "DIALOG: '--size' and '--panel' parameters are ignored if exist."; echo
  else
    show_needed_dialogs
  fi

  prompt -w "Removing the old '${name}${colorscheme}' themes...\n"

  remove_themes; customize_theme; avoid_variant_duplicates;

  prompt -w "Installing '${name}${colorscheme}' themes in '${dest}'...\n";

  prompt -t "--->>> GTK | GNOME Shell | Cinnamon | Metacity | XFWM | Plank <<<---"
  prompt -i "Color variants   : $( IFS=';'; echo "${colors[*]}" )"
  prompt -i "Theme variants   : $( IFS=';'; echo "${themes[*]}" )"
  prompt -i "Opacity variants : $( IFS=';'; echo "${opacities[*]}" )"
  prompt -i "Alt variants     : $( IFS=';'; echo "${alts[*]}" )"
  prompt -i "Icon variant     : ${icon}"
  prompt -i "Nautilus variant : ${nautilus_style}"

  echo; install_themes; echo; prompt -s "Done!"

  if [[ "${libadwaita}" == 'true' ]]; then
    if [[ "$UID" != '0' ]]; then
      install_libadwaita
      echo; prompt -w "Installed ${name} ${opacities} ${colors} gtk-4.0 theme in '${HOME}/.config/gtk-4.0' for libadwaita!"
    else
      echo; prompt -e "Do not run '--libadwaita' option with sudo!"
    fi
  fi

  if (is_running "xfce4-session"); then
    msg="XFCE: you may need to run 'xfce4-panel -r' after changing your theme to fix your panel opacity."
  elif (is_my_distro "solus") && (is_running "gnome-session"); then
    msg="GNOME: you may need to disable 'User Themes' extension to fix your dock."
  # elif (is_running "gnome-session") && [[ "${GNOME_VERSION}" == "3-28" ]]; then
  # msg="GNOME: you may need to disable 'User Themes' extension to fix your logout and authentication dialog."
  fi

  if [[ "${msg}" ]]; then
    echo; prompt -w "${msg}"
    notif_msg="${msg}\n\n${final_msg}"
  else
    notif_msg="${final_msg}"
  fi

  echo; prompt -w "${final_msg}"

  if has_command notify-send && [[ "$UID" != '0' ]]; then
    notify-send "'${name}' theme has been installed. Enjoy!" "${notif_msg}" -i "dialog-information-symbolic"
  fi
fi

echo
