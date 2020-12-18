#!/bin/bash

set  -o errexit

[  GLOBAL::CONF  ]
{
  REPO_DIR=$(cd $(dirname $0) && pwd)
  readonly ROOT_UID=0
}

# Destination directory
if [ "$UID" -eq "$ROOT_UID" ]; then
  DEST_DIR="/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"
else
  DEST_DIR="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"
fi

#COLORS
CDEF=" \033[0m"                                     # default color
CCIN=" \033[0;36m"                                  # info color
CGSC=" \033[0;32m"                                  # success color
CRER=" \033[0;31m"                                  # error color
CWAR=" \033[0;33m"                                  # waring color
b_CDEF=" \033[1;37m"                                # bold default color
b_CCIN=" \033[1;36m"                                # bold info color
b_CGSC=" \033[1;32m"                                # bold success color
b_CRER=" \033[1;31m"                                # bold error color
b_CWAR=" \033[1;33m"                                # bold warning color

usage() {
  printf "%s\n" "Usage: ${0##*/} [OPTIONS...]"
  printf "\n%s\n" "OPTIONS:"
  printf "  %-25s%s\n" "-d, --dark" "install dark theme"
  printf "  %-25s%s\n" "-l, --light" "install light theme"
  printf "  %-25s%s\n" "-h, --help" "Show this help"
}

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

# Check command avalibility
function has_command() {
  command -v $1 > /dev/null
}

operation_canceled() {
  clear
  prompt  -i "\n Operation canceled by user, Bye!"
  exit 1
}

install_theme() {
  if [[ -f ${DEST_DIR}/stylesheet.css ]]; then
    mv -n ${DEST_DIR}/stylesheet.css ${DEST_DIR}/stylesheet.css.back
    cp -r ${REPO_DIR}/stylesheet$color.css ${DEST_DIR}/stylesheet.css
  else
    prompt -i "\n stylesheet.css not exist!"
    exit 0
  fi
}

run_dialog() {
  if [[ -x /usr/bin/dialog ]]; then
    tui=$(dialog --backtitle "dash-to-dock theme installer" \
    --radiolist "Choose your color version:" 15 40 5 \
      1 "light" on  \
      2 "dark" off --output-fd 1 )
      case "$tui" in
        1) color='' ;;
        2) color='-dark' ;;
        *) operation_canceled ;;
     esac
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

# Show terminal user interface for better use
if [[ $# -lt 1 ]] && [[ -x /usr/bin/dialog ]] ; then
  run_dialog
fi

while [[ $# -ge 1 ]]; do
  case "${1}" in
    -l|--light)
      color=''
      ;;
    -d|--dark)
      color='-dark'
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
  shift
done

install_theme

echo
prompt -s Done.

notify-send "All done!" "Go to [Dash to Dock Settings] > [Appearance] > [Use built-in theme] and turn it on!" -i face-smile
