#!/bin/bash

readonly ROOT_UID=0
readonly MAX_DELAY=20 # max delay for user to enter root password

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKGROUND_DIR="/usr/share/backgrounds"
PROPERTIES_DIR="/usr/share/gnome-background-properties"

THEME_VARIANTS=('WhiteSur' 'Monterey')

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

install() {
  local theme="$1"
  prompt -i "\n * Install ${theme} in ${BACKGROUND_DIR}... "
  [[ -d ${BACKGROUND_DIR}/${theme} ]] && rm -rf ${BACKGROUND_DIR}/${theme}
  [[ -f ${PROPERTIES_DIR}/${theme}.xml ]] && rm -rf ${PROPERTIES_DIR}/${theme}.xml
  cp -r ${REPO_DIR}/${theme} ${BACKGROUND_DIR}
  cp -r ${REPO_DIR}/gnome-background-properties/${theme}.xml ${PROPERTIES_DIR}
}

uninstall() {
  local theme="$1"
  prompt -i "\n * Uninstall ${theme}... "
  [[ -d ${BACKGROUND_DIR}/${theme} ]] && rm -rf ${BACKGROUND_DIR}/${theme}
  [[ -f ${PROPERTIES_DIR}/${theme}.xml ]] && rm -rf ${PROPERTIES_DIR}/${theme}.xml
}

while [[ $# -gt 0 ]]; do
  PROG_ARGS+=("${1}")
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

install_access() {
  # Error message
  prompt -e "\n [ Error! ] -> Run me as root ! "

  # persisted execution of the script as root
  read -p "[ Trusted ] Specify the root password : " -t${MAX_DELAY} -s
  [[ -n "$REPLY" ]] && {
    sudo -S <<< $REPLY $0
  } || {
    clear
    prompt -i "\n Operation canceled by user, Bye!"
    exit 1
  }
}

uninstall_access() {
    #Check if password is cached (if cache timestamp not expired yet)
    sudo -n true 2> /dev/null && echo

    if [[ $? == 0 ]]; then
      #No need to ask for password
      sudo "$0" "${PROG_ARGS[@]}"
    else
      #Ask for password
      prompt -e "\n [ Error! ] -> Run me as root! "
      read -p " [ Trusted ] Specify the root password : " -t ${MAX_DELAY} -s

      sudo -S echo <<< $REPLY 2> /dev/null && echo

      if [[ $? == 0 ]]; then
        #Correct password, use with sudo's stdin
        sudo -S "$0" "${PROG_ARGS[@]}" <<< $REPLY
      else
        #block for 3 seconds before allowing another attempt
        sleep 3
        clear
        prompt -e "\n [ Error! ] -> Incorrect password!\n"
        exit 1
      fi
    fi
}

install_wallpaper() {
  if [[ "$UID" == "$ROOT_UID" ]]; then
    echo
    for theme in "${themes[@]}"; do
      install "$theme"
    done
  else
    install_access
    echo
  fi
}

uninstall_wallpaper() {
  if [[ "$UID" == "$ROOT_UID" ]]; then
    echo
    for theme in "${themes[@]}"; do
      uninstall "$theme"
    done
  else
    uninstall_access
    echo
  fi
}

if [[ "${uninstall}" != 'true' ]]; then
  install_wallpaper
else
  uninstall_wallpaper
fi
