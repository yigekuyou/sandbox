#!/usr/bin/zsh

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
LOAD=$(dirname $(readlink -f $0))/LiteLoader
data=data
CMD=$*
QQdir=${CMD%% *}

if [[ ${${CMD##* }##*\.} == appimage ]] {
    unset CMD
    }
if [[  ${QQdir##*\.} != appimage ]] {
echo "only name./appimage"
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
 LiteLoader="--ro-bind $LOAD ${QQ_APP_DIR}/resources/app/LiteLoader \
    --tmpfs ${QQ_APP_DIR}/resources/app/LiteLoader/data \
    --dev-bind-try $LOAD/$data/plugins ${QQ_APP_DIR}/resources/app/LiteLoader/data/plugins \
    --dev-bind-try $LOAD/$data/plugins_data ${QQ_APP_DIR}/resources/app/LiteLoader/data/plugins_data \
    --dev-bind-try $LOAD/$data/config.json ${QQ_APP_DIR}/resources/app/LiteLoader/data/config.json \
    --ro-bind /etc/ssl /etc/ssl \
    --setenv LITELOADERQQNT_PROFILE ${QQ_APP_DIR}/resources/app/LiteLoader/data"
 sed -i 's|"main": "./app_launcher/index.js"|"main": "LiteLoader"|g' ${QQ_APP_DIR}/resources/app/package.json
    }
#
QQ_HOTUPDATE_DIR="${QQ_APP_DIR}/versions"
mkdir ${QQ_HOTUPDATE_DIR}
QQ_HOTUPDATE_VERSION="3.2.0-16449"
QQ_PREVIOUS_VERSIONS=("2.0.1-429" "2.0.1-453" "2.0.2-510" "2.0.3-543" "3.0.0-565" "3.0.0-571" "3.1.0-9332" "3.1.0-9572" "3.1.1-11223" "3.1.2-12912" "3.1.2-13107")
cd ${QQ_HOTUPDATE_DIR}
wget "https://aur.archlinux.org/cgit/aur.git/plain/config.json?h=linuxqq-nt-bwrap" --output-document=config.json
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
    --ro-bind /usr/bin/wl-copy /bin/xdg-open \
    --ro-bind /usr/bin/kdialog /usr/bin/kdialog  \
    --ro-bind /usr/bin/bash /bin/sh \
    --ro-bind /usr/bin/bash /bin/bash \
    --ro-bind /usr /usr \
    --ro-bind /etc/machine-id /etc/machine-id \
    --ro-bind /etc/nsswitch.conf /etc/nsswitch.conf \
    --ro-bind-try /run/systemd/userdb /run/systemd/userdb \
    --ro-bind /etc/resolv.conf /etc/resolv.conf \
    --ro-bind /etc/localtime /etc/localtime \
    --ro-bind-try /etc/fonts /etc/fonts \
    --dev-bind /dev /dev \
    --ro-bind /sys /sys \
    --ro-bind /etc/passwd /etc/passwd \
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
    --tmpfs /dev/shm  \
    --ro-bind-try "${HOME}/.icons" "${HOME}/.icons" \
    --ro-bind-try "${HOME}/.local/share/.icons" "${HOME}/.local/share/.icons" \
    --ro-bind-try "${XDG_CONFIG_HOME}/gtk-3.0" "${XDG_CONFIG_HOME}/gtk-3.0" \
    --setenv IBUS_USE_PORTAL 1 \
    --setenv APPDIR ${APPDIR} \
    ${LiteLoader} ${HOTUPDATE}  \
    --ro-bind-try "${XAUTHORITY}" "${XAUTHORITY}" \
    ${APPDIR}/AppRun ${CMD#* }"
bwrap `echo $Part`
rm -rf /tmp/QQ
