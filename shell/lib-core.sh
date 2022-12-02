# WARNING: Please make this shell not working-directory dependant, for example
# instead of using 'ls blabla', use 'ls "${REPO_DIR}/blabla"'
#
# WARNING: Don't use "cd" in this shell, use it in a subshell instead,
# for example ( cd blabla && do_blabla ) or $( cd .. && do_blabla )

set -Eeo pipefail

if [[ ! "${REPO_DIR}" ]]; then
  echo "Please define 'REPODIR' variable"; exit 1
elif [[ "${WHITESUR_SOURCE[@]}" =~ "lib-core.sh" ]]; then
  echo "'lib-core.sh' is already imported"; exit 1
fi

WHITESUR_SOURCE=("lib-core.sh")

###############################################################################
#                                VARIABLES                                    #
###############################################################################

#--------------System--------------#

export WHITESUR_PID=$$
MY_USERNAME="${SUDO_USER:-$(logname 2> /dev/null || echo "${USER}")}"
MY_HOME=$(getent passwd "${MY_USERNAME}" | cut -d: -f6)

if command -v gnome-shell &> /dev/null; then
  SHELL_VERSION="$(gnome-shell --version | cut -d ' ' -f 3 | cut -d . -f -1)"
  if [[ "${SHELL_VERSION:-}" -ge "42" ]]; then
    GNOME_VERSION="42-0"
  elif [[ "${SHELL_VERSION:-}" -ge "40" ]]; then
    GNOME_VERSION="40-0"
  else
    GNOME_VERSION="3-28"
  fi
else
  GNOME_VERSION="none"
fi

#----------Program options-------------#
SASSC_OPT="-t expanded"

if [[ "$(uname -s)" =~ "BSD" || "$(uname -s)" == "Darwin" ]]; then
  SED_OPT="-i """
else
  SED_OPT="-i"
fi

SUDO_BIN="$(which sudo)"

#------------Directories--------------#
THEME_SRC_DIR="${REPO_DIR}/src"
DASH_TO_DOCK_SRC_DIR="${REPO_DIR}/src/other/dash-to-dock"
DASH_TO_DOCK_DIR_ROOT="/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"
DASH_TO_DOCK_DIR_HOME="${MY_HOME}/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"
GNOME_SHELL_EXTENSION_DIR="${MY_HOME}/.local/share/gnome-shell/extensions"
FIREFOX_SRC_DIR="${REPO_DIR}/src/other/firefox"
FIREFOX_DIR_HOME="${MY_HOME}/.mozilla/firefox"
FIREFOX_THEME_DIR="${MY_HOME}/.mozilla/firefox/firefox-themes"
FIREFOX_FLATPAK_DIR_HOME="${MY_HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox"
FIREFOX_FLATPAK_THEME_DIR="${MY_HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/firefox-themes"
FIREFOX_SNAP_DIR_HOME="${MY_HOME}/snap/firefox/common/.mozilla/firefox"
FIREFOX_SNAP_THEME_DIR="${MY_HOME}/snap/firefox/common/.mozilla/firefox/firefox-themes"
export WHITESUR_TMP_DIR="/tmp/WhiteSur.lock"

if [[ -w "/root" ]]; then
  THEME_DIR="/usr/share/themes"
else
  THEME_DIR="$HOME/.themes"
fi

#--------------GDM----------------#
WHITESUR_GS_DIR="/usr/share/gnome-shell/theme/WhiteSur"
COMMON_CSS_FILE="/usr/share/gnome-shell/theme/gnome-shell.css"
UBUNTU_CSS_FILE="/usr/share/gnome-shell/theme/ubuntu.css"
ZORIN_CSS_FILE="/usr/share/gnome-shell/theme/zorin.css"
ETC_CSS_FILE="/etc/alternatives/gdm3.css"
ETC_GR_FILE="/etc/alternatives/gdm3-theme.gresource"
YARU_GR_FILE="/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource"
POP_OS_GR_FILE="/usr/share/gnome-shell/theme/Pop/gnome-shell-theme.gresource"
ZORIN_GR_FILE="/usr/share/gnome-shell/theme/ZorinBlue-Light/gnome-shell-theme.gresource"
MISC_GR_FILE="/usr/share/gnome-shell/gnome-shell-theme.gresource"
GS_GR_XML_FILE="${THEME_SRC_DIR}/main/gnome-shell/gnome-shell-theme.gresource.xml"

#-------------Theme---------------#
THEME_NAME="WhiteSur"
COLOR_VARIANTS=('Light' 'Dark')
OPACITY_VARIANTS=('normal' 'solid')
ALT_VARIANTS=('normal' 'alt')
THEME_VARIANTS=('default' 'blue' 'purple' 'pink' 'red' 'orange' 'yellow' 'green' 'grey')
ICON_VARIANTS=('standard' 'simple' 'gnome' 'ubuntu' 'tux' 'arch' 'manjaro' 'fedora' 'debian' 'void' 'opensuse' 'popos' 'mxlinux' 'zorin')
SIDEBAR_SIZE_VARIANTS=('default' '180' '220' '240' '260' '280')
PANEL_OPACITY_VARIANTS=('default' '30' '45' '60' '75')
PANEL_SIZE_VARIANTS=('default' 'smaller' 'bigger')
NAUTILUS_STYLE_VARIANTS=('stable' 'normal' 'mojave' 'glassy')

#--------Customization, default values----------#
dest="${THEME_DIR}"
name="${THEME_NAME}"
colors=("${COLOR_VARIANTS}")
opacities=("${OPACITY_VARIANTS}")
alts=("${ALT_VARIANTS[0]}")
themes=("${THEME_VARIANTS[0]}")
icon="${ICON_VARIANTS[0]}"
sidebar_size="${SIDEBAR_SIZE_VARIANTS[0]}"
panel_opacity="${PANEL_OPACITY_VARIANTS[0]}"
panel_size="${PANEL_SIZE_VARIANTS[0]}"
nautilus_style="${NAUTILUS_STYLE_VARIANTS[0]}"
background="blank"
compact="true"
colorscheme=""

#--Ambigous arguments checking and overriding default values--#
declare -A has_set=([-b]="false" [-s]="false" [-p]="false" [-P]="false" [-d]="false" [-n]="false" [-a]="false" [-o]="false" [-c]="false" [-i]="false" [-t]="false" [-N]="false")
declare -A need_dialog=([-b]="false" [-s]="false" [-p]="false" [-P]="false" [-d]="false" [-n]="false" [-a]="false" [-o]="false" [-c]="false" [-i]="false" [-t]="false" [-N]="false")

#------------Tweaks---------------#
need_help="false"
uninstall="false"
interactive="false"
silent_mode="false"

no_darken="false"
no_blur="false"

firefox="false"
edit_firefox="false"
flatpak="false"
snap="false"
gdm="false"
dash_to_dock="false"
max_round="false"
showapps_normal="false"

#--------------Misc----------------#
msg=""
final_msg="Run '${0} --help' to explore more customization features!"
notif_msg=""
process_ids=()
# This is important for 'udo' because 'return "${result}"' is considered the
# last command in 'BASH_COMMAND' variable
WHITESUR_COMMAND=""
export ANIM_PID="0"
has_any_error="false"
swupd_packages=""
# '/' ending is required in 'swupd_url'
swupd_url="https://cdn.download.clearlinux.org/current/x86_64/os/Packages/"
swupd_ver_url="https://cdn.download.clearlinux.org/latest"
swupd_prepared="false"
xbps_prepared="false"

#------------Decoration-----------#
export c_default="\033[0m"
export c_blue="\033[1;34m"
export c_magenta="\033[1;35m"
export c_cyan="\033[1;36m"
export c_green="\033[1;32m"
export c_red="\033[1;31m"
export c_yellow="\033[1;33m"

anim=(
  "${c_blue}•${c_green}•${c_red}•${c_magenta}•    "
  " ${c_green}•${c_red}•${c_magenta}•${c_blue}•   "
  "  ${c_red}•${c_magenta}•${c_blue}•${c_green}•  "
  "   ${c_magenta}•${c_blue}•${c_green}•${c_red}• "
  "    ${c_blue}•${c_green}•${c_red}•${c_magenta}•"
)

# Check command availability
has_command() {
  command -v "$1" &> /dev/null
}

has_flatpak_app() {
  flatpak list --columns=application | grep "${1}" &> /dev/null || return 1
}

has_snap_app() {
  snap list "${1}" &> /dev/null || return 1
}

is_my_distro() {
  [[ "$(cat '/etc/os-release' | awk -F '=' '/ID/{print $2}')" =~ "${1}" ]]
}

is_running() {
  pgrep "$1" &> /dev/null
}

###############################################################################
#                              CORE UTILITIES                                 #
###############################################################################

start_animation() {
  [[ "${silent_mode}" == "true" ]] && return 0

  setterm -cursor off

  (
    while true; do
      for i in {0..4}; do
        echo -ne "\r\033[2K                         ${anim[i]}"
        sleep 0.1
      done

      for i in {4..0}; do
        echo -ne "\r\033[2K                         ${anim[i]}"
        sleep 0.1
      done
    done
  ) &

  export ANIM_PID="${!}"
}

stop_animation() {
  [[ "${silent_mode}" == "true" ]] && return 0

  [[ -e "/proc/${ANIM_PID}" ]] && kill -13 "${ANIM_PID}"
  setterm -cursor on
}

# Echo like ... with flag type and display message colors
prompt() {
  case "${1}" in
    "-s")
      echo -e "  ${c_green}${2}${c_default}" ;;    # print success message
    "-e")
      echo -e "  ${c_red}${2}${c_default}" ;;      # print error message
    "-w")
      echo -e "  ${c_yellow}${2}${c_default}" ;;   # print warning message
    "-i")
      echo -e "  ${c_cyan}${2}${c_default}" ;;     # print info message
    "-t")
      echo -e "  ${c_magenta}${2}${c_default}" ;;     # print title message
  esac
}

###############################################################################
#                               SELF SAFETY                                   #
###############################################################################
##### This is the core of error handling, make sure there's no error here #####

### TODO: return "lockWhiteSur()" back for non functional syntax error handling
###       and lock dir removal after immediate terminal window closing

if [[ -d "${WHITESUR_TMP_DIR}" ]]; then
  start_animation; sleep 2; stop_animation; echo

  if [[ -d "${WHITESUR_TMP_DIR}" ]]; then
    prompt -e "ERROR: Whitesur installer or tweaks is already running. Probably it's run by '$(ls -ld "${WHITESUR_TMP_DIR}" | awk '{print $3}')'"
    exit 1
  fi
fi

rm -rf "${WHITESUR_TMP_DIR}"
mkdir -p "${WHITESUR_TMP_DIR}"; exec 2> "${WHITESUR_TMP_DIR}/error_log.txt"

signal_exit() {
  rm -rf "${WHITESUR_TMP_DIR}"
  stop_animation
}

signal_abort() {
  signal_exit
  prompt -e "\n\n  Oops! Operation has been aborted...\n\n"
  exit 1
}

signal_error() {
  # TODO: make this more accurate

  IFS=$'\n'
  local sources=($(basename -a "${WHITESUR_SOURCE[@]}" "${BASH_SOURCE[@]}" | sort -u))
  local dist_ids=($(awk -F '=' '/ID/{print $2}' "/etc/os-release" | tr -d '"' | sort -Vru))
  local repo_ver=""
  local lines=()
  local log="$(awk '{printf "\033[1;31m  >>> %s\n", $0}' "${WHITESUR_TMP_DIR}/error_log.txt" || echo "")"

  if ! repo_ver="$(cd "${REPO_DIR}"; git log -1 --date=format-local:"%FT%T%z" --format="%ad")"; then
    if ! repo_ver="$(date -r "${REPO_DIR}" +"%FT%T%z")"; then
      repo_ver="unknown"
    fi
  fi

  # Some computer may have a bad performance. We need to avoid the error log
  # to be cut. Sleeping for awhile may help
  sleep 0.75; clear

  prompt -e "\n\n  Oops! Operation failed...\n"
  prompt -e "=========== ERROR LOG ==========="

  if [[ "${log}" ]] ; then
    echo -e "${log}"
  else
    prompt -e "\n>>>>>>> No error log found <<<<<<"
  fi

  prompt -e "\n  =========== ERROR INFO =========="
  prompt -e "FOUND  :"

  for i in "${sources[@]}"; do
    lines=($(grep -Fn "${WHITESUR_COMMAND:-${BASH_COMMAND}}" "${REPO_DIR}/${i}" | cut -d : -f 1 || echo ""))
    prompt -e "  >>> ${i}$(IFS=';'; [[ "${lines[*]}" ]] && echo " at ${lines[*]}")"
  done

  prompt -e "SNIPPET:\n    >>> ${WHITESUR_COMMAND:-${BASH_COMMAND}}"
  prompt -e "TRACE  :"

  for i in "${FUNCNAME[@]}"; do
    prompt -e "  >>> ${i}"
  done

  prompt -e "\n  =========== SYSTEM INFO ========="
  prompt -e "DISTRO : $(IFS=';'; echo "${dist_ids[*]}")"
  prompt -e "SUDO   : $([[ -w "/root" ]] && echo "yes" || echo "no")"
  prompt -e "GNOME  : ${GNOME_VERSION}"
  prompt -e "REPO   : ${repo_ver}\n"

  if [[ "$(grep -ril "Release" "${WHITESUR_TMP_DIR}/error_log.txt")" == "${WHITESUR_TMP_DIR}/error_log.txt" ]]; then
    prompt -w "HINT: You can run: 'sudo apt install sassc libglib2.0-dev libxml2-utils' on ubuntu 18.04 or 'sudo apt install sassc libglib2.0-dev-bin' on ubuntu >= 20.04 \n"
  fi

  prompt -i "HINT: You can google or report to us the info above \n"
  prompt -i "https://github.com/vinceliuice/WhiteSur-gtk-theme/issues \n"

  rm -rf "${WHITESUR_TMP_DIR}"; exit 1
}

trap 'signal_exit' EXIT
trap 'signal_error' ERR
trap 'signal_abort' INT TERM TSTP

###############################################################################
#                              USER UTILITIES                                 #
###############################################################################

ask() {
  [[ "${silent_mode}" == "true" ]] && return 0

  echo -ne "${c_magenta}"
  read -p "  ${2}: " ${1} 2>&1
  echo -ne "${c_default}"
}

confirm() {
  [[ "${silent_mode}" == "true" ]] && return 0

  while [[ "${!1}" != "y" && "${!1}" != "n" ]]; do
    ask ${1} "${2} (y/n)"
  done
}

dialogify() {
  if [[ "${silent_mode}" == "true" ]]; then
    prompt -w "Oops... silent mode has been activated so we can't show the dialog"
    return 0
  fi

  local lists=""
  local i=0
  local result=""
  local n_result=4

  for list in "${@:4}"; do
    lists+=" ${i} ${list} off "; ((i+=1))
  done

  result="$(dialog --backtitle "${2}" --radiolist "${3}" 0 0 0 ${lists} --output-fd 1 || echo "x")"
  clear

  if [[ "${result}" != "x" ]]; then
    ((n_result+=result))
    printf -v "${1}" "%s" "${!n_result}"
  else
    signal_abort
  fi
}

helpify_title() {
  printf "${c_cyan}%s${c_blue}%s ${c_green}%s\n\n" "Usage: " "$0" "[OPTIONS...]"
  printf "${c_cyan}%s\n" "OPTIONS:"
}

helpify() {
  printf "  ${c_blue}%s ${c_green}%s\n ${c_magenta}%s. ${c_cyan}%s\n\n${c_default}" "${1}" "${2}" "${3}" "${4}"
}

###############################################################################
#                                 PARAMETERS                                  #
###############################################################################

destify() {
  case "${1}" in
    normal|default|standard)
      echo "" ;;
    *)
      echo "-${1}" ;;
  esac
}

parsimplify() {
  case "${1}" in
    --name|-n)
      # workaround for echo
      echo "~-n" | cut -c 2- ;;
    --dest)
      echo "-d" ;;
    --size)
      echo "-s" ;;
    --alt)
      echo "-a" ;;
    --opacity)
      echo "-o" ;;
    --color)
      echo "-c" ;;
    --icon)
      echo "-i" ;;
    --theme)
      echo "-t" ;;
    --panel-opacity)
      echo "-p" ;;
    --panel-size)
      echo "-P" ;;
    --nautilus-style)
      echo "-N" ;;
    --background)
      echo "-b" ;;
    *)
      echo "${1}" ;;
  esac
}

check_param() {
  local global_param="$(parsimplify "${1}")"
  local display_param="${2}" # used for aliases
  local value="${3}"
  local must_not_ambigous="${4}" # options: must, optional, not-at-all
  local must_have_value="${5}"   # options: must, optional, not-at-all
  local value_must_found="${6}"  # options: must, optional, not-at-all
  local allow_all_choice="${7}"  # options: true, false

  local has_any_ambiguity_error="false"
  local variant_found="false"

  if [[ "${silent_mode}" == "true" ]]; then
    must_not_ambigous="must"
    must_have_value="must"
    value_must_found="must"
  fi

  if [[ "${has_set["${global_param}"]}" == "true" ]]; then
    need_dialog["${global_param}"]="true"

    case "${must_not_ambigous}" in
      must)
        prompt -e "ERROR: Ambigous '${display_param}' option. Choose one only."; has_any_error="true" ;;
      optional)
        prompt -w "WARNING: Ambigous '${display_param}' option. We'll show a chooser dialog when possible" ;;
    esac
  fi

  if [[ "${value}" == "" || "${value}" == "-"*  ]]; then
    need_dialog["${global_param}"]="true"

    case "${must_have_value}" in
      must)
        prompt -e "ERROR: '${display_param}' can't be empty."; has_any_error="true" ;;
      optional)
        prompt -w "WARNING: '${display_param}' can't be empty. We'll show a chooser dialog when possible" ;;
    esac

    has_set["${global_param}"]="true"; return 1
  else
    if [[ "${has_set["${global_param}"]}" == "false" ]]; then
      case "${global_param}" in
        -a)
          alts=() ;;
        -o)
          opacities=() ;;
        -c)
          colors=() ;;
        -t)
          themes=() ;;
      esac
    fi

    case "${global_param}" in
      -d)
        if [[ "$(readlink -m "${value}")" =~ "${REPO_DIR}" ]]; then
          prompt -e "'${display_param}' ERROR: Can't install in the source directory."
          has_any_error="true"
        elif [[ ! -w "${value}" && ! -w "$(dirname "${value}")" ]]; then
          prompt -e "'${display_param}' ERROR: You have no permission to access that directory."
          has_any_error="true"
        else
          if [[ ! -d "${value}" ]]; then
            prompt -w "Destination directory does not exist. Let's make a new one..."; echo
            mkdir -p "${value}"
          fi

          dest="${value}"
        fi

        remind_relative_path "${display_param}" "${value}"; variant_found="skip" ;;
      -b)
        if [[ "${value}" == "blank" || "${value}" == "default" ]]; then
          background="${value}"
        elif [[ ! -r "${value}" ]]; then
          prompt -e "'${display_param}' ERROR: Image file is not found or unreadable."
          has_any_error="true"
        elif file "${value}" | grep -qE "image|bitmap"; then
          background="${value}"
        else
          prompt -e "'${display_param}' ERROR: Invalid image file."
          has_any_error="true"
        fi

        remind_relative_path "${display_param}" "${value}"; variant_found="skip" ;;
      -n)
        name="${value}"; variant_found="skip" ;;
      -s)
        for i in {0..5}; do
          if [[ "${value}" == "${SIDEBAR_SIZE_VARIANTS[i]}" ]]; then
            sidebar_size="${value}"; variant_found="true"; break
          fi
        done ;;
      -p)
        for i in {0..4}; do
          if [[ "${value}" == "${PANEL_OPACITY_VARIANTS[i]}" ]]; then
            panel_opacity="${value}"; variant_found="true"; break
          fi
        done ;;
      -P)
        for i in {0..2}; do
          if [[ "${value}" == "${PANEL_SIZE_VARIANTS[i]}" ]]; then
            panel_size="${value}"; variant_found="true"; break
          fi
        done ;;
      -a)
        if [[ "${value}" == "all" ]]; then
          for i in {0..2}; do
            alts+=("${ALT_VARIANTS[i]}")
          done

          variant_found="true"
        else
          for i in {0..2}; do
            if [[ "${value}" == "${ALT_VARIANTS[i]}" ]]; then
              alts+=("${ALT_VARIANTS[i]}"); variant_found="true"; break
            fi
          done
        fi ;;
      -o)
        for i in {0..1}; do
          if [[ "${value}" == "${OPACITY_VARIANTS[i]}" ]]; then
            opacities+=("${OPACITY_VARIANTS[i]}"); variant_found="true"; break
          fi
        done ;;
      -c)
        for i in {0..1}; do
          if [[ "${value}" == "${COLOR_VARIANTS[i]}" ]]; then
            colors+=("${COLOR_VARIANTS[i]}"); variant_found="true"; break
          fi
        done ;;
      -i)
        for i in {0..13}; do
          if [[ "${value}" == "${ICON_VARIANTS[i]}" ]]; then
            icon="${ICON_VARIANTS[i]}"; variant_found="true"; break
          fi
        done ;;
      -t)
        if [[ "${value}" == "all" ]]; then
          for i in {0..8}; do
            themes+=("${THEME_VARIANTS[i]}")
          done

          variant_found="true"
        else
          for i in {0..8}; do
            if [[ "${value}" == "${THEME_VARIANTS[i]}" ]]; then
              themes+=("${THEME_VARIANTS[i]}")
              variant_found="true"
              break
            fi
          done
        fi ;;
      -N)
        for i in {0..3}; do
          if [[ "${value}" == "${NAUTILUS_STYLE_VARIANTS[i]}" ]]; then
            nautilus_style="${NAUTILUS_STYLE_VARIANTS[i]}"; variant_found="true"; break
          fi
        done ;;
    esac

    if [[ "${variant_found}" == "false" && "${variant_found}" != "skip" ]]; then
      case "${value_must_found}" in
        must)
          prompt -e "ERROR: Unrecognized '${display_param}' variant: '${value}'."; has_any_error="true" ;;
        optional)
          prompt -w "WARNING: '${display_param}' variant of '${value}' isn't recognized. We'll show a chooser dialog when possible"
          need_dialog["${global_param}"]="true" ;;
      esac
    elif [[ "${allow_all_choice}" == "false" && "${value}" == "all" ]]; then
      prompt -e "ERROR: Can't choose all '${display_param}' variants."; has_any_error="true"
    fi

    has_set["${global_param}"]="true"; return 0
  fi
}

avoid_variant_duplicates() {
  colors=($(printf "%s\n" "${colors[@]}" | sort -u))
  opacities=($(printf "%s\n" "${opacities[@]}" | sort -u))
  alts=($(printf "%s\n" "${alts[@]}" | sort -u))
  themes=($(printf "%s\n" "${themes[@]}" | sort -u))
}

# 'finalize_argument_parsing' is in the 'MISC' section

###############################################################################
#                                   FILES                                     #
###############################################################################

restore_file() {
  if [[ -f "${1}.bak" || -d "${1}.bak" ]]; then
    case "${2}" in
      sudo)
        sudo rm -rf "${1}"; sudo mv "${1}"{".bak",""} ;;
      udo)
        udo rm -rf "${1}"; udo mv "${1}"{".bak",""} ;;
      *)
        rm -rf "${1}"; mv "${1}"{".bak",""} ;;
    esac
  fi
}

backup_file() {
  if [[ -f "${1}" || -d "${1}" ]]; then
    case "${2}" in
      sudo)
        sudo mv -n "${1}"{"",".bak"} ;;
      udo)
        udo mv -n "${1}"{"",".bak"} ;;
      *)
        mv -n "${1}"{"",".bak"} ;;
    esac
  fi
}

udoify_file() {
  if [[ -f "${1}" && "$(ls -ld "${1}" | awk '{print $3}')" != "${MY_USERNAME}" ]]; then
    sudo chown "${MY_USERNAME}:" "${1}"
  fi
}

check_theme_file() {
  [[ -f "${1}" || -f "${1}.bak" ]]
}

remind_relative_path() {
  [[ "${2}" =~ "~" ]] && prompt -w "'${1}' REMEMBER: ~/'path to somewhere' and '~/path to somewhere' are different."
}

###############################################################################
#                                    MISC                                     #
###############################################################################

sudo() {
  local result="0"

  prompt -w "Executing '$(echo "${@}" | cut -c -35 )...' as root"

  if ! ${SUDO_BIN} -n true &> /dev/null; then
    echo -e "\n ${c_magenta} Authentication is required${c_default} ${c_green}(Please input your password):${c_default} \n"
  fi

  if [[ -p /dev/stdin ]]; then
    ${SUDO_BIN} "${@}" < /dev/stdin || result="${?}"
  else
    ${SUDO_BIN} "${@}" || result="${?}"
  fi

  [[ "${result}" != "0" ]] && WHITESUR_COMMAND="${*}"

  return "${result}"
}

udo() {
  local result="0"

  # Just in case. We put the prompt here to make it less annoying
  if ! ${SUDO_BIN} -u "${MY_USERNAME}" -n true &> /dev/null; then
    prompt -w "Executing '$(echo "${@}" | cut -c -35 )...' as user"
    echo -e "${c_magenta} Authentication is required${c_default} ${c_green}(Please input your password):${c_default}"
  fi

  if [[ -p /dev/stdin ]]; then
    ${SUDO_BIN} -u "${MY_USERNAME}" "${@}" < /dev/stdin || result="${?}"
  else
    ${SUDO_BIN} -u "${MY_USERNAME}" "${@}" || result="${?}"
  fi

  [[ "${result}" != "0" ]] && WHITESUR_COMMAND="${*}"

  return "${result}"
}

full_sudo() {
  if [[ ! -w "/root" ]]; then
    prompt -e "ERROR: '${1}' needs a root priviledge. Please run this '${0}' as root"
    has_any_error="true"
  fi
}

get_utc_epoch_time() {
  local time=""
  local epoch=""

  if exec 3<> "/dev/tcp/iana.org/80"; then
    echo -e "GET / HTTP/1.1\nHost: iana.org\n\n" >&3

    while read -r -t 2 line 0<&3; do
      if [[ "${line}" =~ "Date:" ]]; then
        time="${line#*':'}"; exec 3<&-; break
      fi
    done

    exec 3<&-

    if [[ "${time}" ]]; then
      epoch="$(date -d "${time}" "+%s")"
      echo "$((epoch + 2))"
    else
      return 1
    fi
  else
    exec 3<&-; return 1
  fi
}

usage() {
  prompt -e "Usage function is not implemented"; exit 1
}

finalize_argument_parsing() {
  if [[ "${need_help}" == "true" ]]; then
    echo; usage; echo
    [[ "${has_any_error}" == "true" ]] && exit 1 || exit 0
  elif [[ "${has_any_error}" == "true" ]]; then
    echo; prompt -i "Try '$0 --help' for more information."; echo; exit 1
  fi
}
