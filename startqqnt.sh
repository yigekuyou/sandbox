#!/usr/bin/zsh

USER_RUN_DIR="/run/user/$(id -u)"
XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
FONTCONFIG_HOME="${XDG_CONFIG_HOME}/fontconfig"

function command_exists() {
	local command="$1"
	command -v "${command}" >/dev/null 2>&1
}

function show_error_dialog() {
    title="linuxqq-nt-bwrap"
    if command_exists kdialog; then
        kdialog --error "$1" --title "$title" --icon qq
    elif command_exists zenity; then
        zenity --error --title "$title" --icon-name qq --text "$1"
    else
        all_off="$(tput sgr0)"
        bold="${all_off}$(tput bold)"
        blue="${bold}$(tput setaf 4)"
        yellow="${bold}$(tput setaf 3)"
        printf "${blue}==>${yellow} ${bold} $1${all_off}\n"
    fi
}


QQ_APP_DIR=/tmp/QQ/squashfs-root
APPDIR=${QQ_APP_DIR}
LOAD=$(dirname $(readlink -f $0))/LiteLoaderQQNT
data=data
CMD=$*
QQdir=${CMD%% *}

if [[ ${${CMD##* }##*\.} == AppImage ]] {
    unset CMD
    }
if [[  ${QQdir##*\.} != AppImage ]] {
echo "only name./AppImage"
return -1
}

trap 'rm -rf /tmp/QQ ; return 0' INT TERM
mkdir /tmp/QQ
chmod 700 /tmp/QQ
cp $QQdir /tmp/QQ
cd /tmp/QQ
chmod +x /tmp/QQ/${QQdir##*\/}
./${QQdir##*\/} --appimage-extract > /dev/null
rm -rf ${QQ_APP_DIR}/resources/app/fonts
rm -f ${QQ_APP_DIR}/resources/app/{libssh2.so.1,libunwind*,sharp-lib/libvips-cpp.so.42}
 if [[ -d "${LOAD}" ]] {
 LiteLoader="--dev-bind $LOAD ${QQ_APP_DIR}/resources/app/LiteLoader \
    --dev-bind-try $LOAD/$data/plugins ${QQ_APP_DIR}/resources/app/LiteLoader/data/plugins \
    --dev-bind-try $LOAD/$data/plugins_data ${QQ_APP_DIR}/resources/app/LiteLoader/data/plugins_data \
    --dev-bind-try $LOAD/$data/config.json ${QQ_APP_DIR}/resources/app/LiteLoader/data/config.json \
    --ro-bind /etc/ssl /etc/ssl \
    --setenv LITELOADERQQNT_PROFILE ${QQ_APP_DIR}/resources/app/LiteLoader/data"
    grep -q $LOAD ${QQ_APP_DIR}/resources/app/app_launcher/index.js|| sed -i "1 i require(\"${QQ_APP_DIR}/resources/app/LiteLoader/\");" ${QQ_APP_DIR}/resources/app/app_launcher/index.js
    }
#
QQ_HOTUPDATE_DIR="${QQ_APP_DIR}/versions"
mkdir ${QQ_HOTUPDATE_DIR}
QQ_HOTUPDATE_VERSION="3.2.0-16449"
QQ_PREVIOUS_VERSIONS=("2.0.1-429" "2.0.1-453" "2.0.2-510" "2.0.3-543" "3.0.0-565" "3.0.0-571" "3.1.0-9332" "3.1.0-9572" "3.1.1-11223" "3.1.2-12912" "3.1.2-13107" "3.2.0-16449" "3.2.0-16605" "3.2.0-16736" "3.2.1-16950" "3.2.1-17153" "3.2.1-17260" "3.2.1-17412" "3.2.1-17654" "3.2.1-17749" "3.2.1-17816" "3.2.2-18163" "3.2.5-20979" "3.2.5-20811")
cd ${QQ_HOTUPDATE_DIR}
rm -rf "${QQ_HOTUPDATE_DIR}/${QQ_HOTUPDATE_VERSION}"
cd /tmp/QQ
HOTUPDATE="--ro-bind $APPDIR/resources/app ${QQ_HOTUPDATE_DIR}/${QQ_HOTUPDATE_VERSION}"

rm -f /tmp/QQ/${QQdir##*\/}
if [[ -z "${QQ_DOWNLOAD_DIR}" ]] {
    if [[ -z "${XDG_DOWNLOAD_DIR}" ]] {
        XDG_DOWNLOAD_DIR="$(xdg-user-dir DOWNLOAD)"
        }
    QQ_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
    }
USER_RUN_DIR="/run/user/$(id -u)"
Part="--new-session --cap-drop ALL --unshare-user-try --unshare-pid --unshare-cgroup-try --die-with-parent \
    --symlink usr/lib /lib \
    --symlink usr/lib64 /lib64 \
    --ro-bind /usr /usr \
    --ro-bind /usr/bin/flatpak-xdg-open /usr/bin/xdg-open \
    --ro-bind /usr/bin/kdialog /usr/bin/kdialog  \
    --ro-bind /usr/bin/bash /bin/bash \
    --ro-bind /usr/bin/zsh /bin/sh \
    --ro-bind /etc/machine-id /etc/machine-id \
    --ro-bind /etc/nsswitch.conf /etc/nsswitch.conf \
    --ro-bind-try /run/systemd/userdb /run/systemd/userdb \
    --ro-bind /etc/resolv.conf /etc/resolv.conf \
    --ro-bind /etc/localtime /etc/localtime \
    --ro-bind /etc/vulkan /etc/vulkan \
    --ro-bind-try /etc/fonts /etc/fonts \
    --dev-bind /dev /dev \
    --ro-bind /sys /sys \
    --ro-bind /etc/passwd /etc/passwd \
    --ro-bind-try /run/systemd/userdb /run/systemd/userdb \
    --ro-bind /etc/resolv.conf /etc/resolv.conf \
    --ro-bind /etc/localtime /etc/localtime \
    --ro-bind ${QQ_HOTUPDATE_DIR} ${XDG_CONFIG_HOME}/QQ/versions \
    --proc /proc \
    --dev-bind /run/dbus /run/dbus \
    --ro-bind-try /etc/fonts /etc/fonts \
    --dev-bind /tmp /tmp \
    --tmpfs ${HOME}/.config/QQ \
    --bind "${USER_RUN_DIR}" "${USER_RUN_DIR}" \
    --bind-try "${QQ_DOWNLOAD_DIR}" "${QQ_DOWNLOAD_DIR}" \
    --bind "${QQ_APP_DIR}" "${QQ_APP_DIR}" \
    --ro-bind-try "${FONTCONFIG_HOME}" "${FONTCONFIG_HOME}" \
    --tmpfs /dev/shm  \
    --ro-bind-try "${HOME}/.icons" "${HOME}/.icons" \
    --ro-bind-try "${HOME}/.local/share/.icons" "${HOME}/.local/share/.icons" \
    --ro-bind-try "${XDG_CONFIG_HOME}/gtk-3.0" "${XDG_CONFIG_HOME}/gtk-3.0" \
    --setenv IBUS_USE_PORTAL 1 \
    --setenv APPDIR ${APPDIR} \
    ${LiteLoader} ${HOTUPDATE}  \
    --ro-bind-try "${XAUTHORITY}" "${XAUTHORITY}"  \
    ${APPDIR}/AppRun ${CMD#* }"
    #strace -y -o /tmp/logs/log
bwrap `echo $Part`
rm -rf /tmp/QQ
