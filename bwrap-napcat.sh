#!/usr/bin/zsh

USER_RUN_DIR="/run/user/$(id -u)"
XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
FONTCONFIG_HOME="${XDG_CONFIG_HOME}/fontconfig"
XMODIFIERS=@im=fcitx

function command_exists() {
	local command="$1"
	command -v "${command}" >/dev/null 2>&1
}

function show_error_dialog() {
    title="NCqq-nt-bwrap"
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

QQ_APP_DIR=/tmp/NCQQ/squashfs-root
APPDIR=${QQ_APP_DIR}
LOAD=$(dirname $(readlink -f $0))/NapCat
CMD=$*
QQdir=${CMD%% *}
if [[ ${${CMD##* }##*\.} == AppImage ]] {
    unset CMD
    }
if [[  ${QQdir##*\.} != AppImage ]] {
echo "only name./AppImage"
return -1
}
trap 'rm -rf /tmp/NCQQ ; return 0' INT TERM
mkdir /tmp/NCQQ
chmod 700 /tmp/NCQQ
cp $QQdir /tmp/NCQQ
cd /tmp/NCQQ
chmod +x /tmp/NCQQ/${QQdir##*\/}
./${QQdir##*\/} --appimage-extract > /dev/null
rm /tmp/QQ/${QQdir##*\/}
rm -rf ${QQ_APP_DIR}/resources/app/fonts
rm -f ${QQ_APP_DIR}/resources/app/{libssh2.so.1,libunwind*,sharp-lib/libvips-cpp.so.42}
if [[ -d "${LOAD}" ]] {
mkdir ${QQ_APP_DIR}/resources/app/NapCat
NCqq="--ro-bind $LOAD/package.json ${QQ_APP_DIR}/resources/app/NapCat/package.json \
--ro-bind $LOAD/node_modules ${QQ_APP_DIR}/resources/app/NapCat/node_modules \
--dev-bind $LOAD/config ${QQ_APP_DIR}/resources/app/NapCat/config \
--ro-bind $LOAD/napcat.cjs ${QQ_APP_DIR}/resources/app/NapCat/napcat.cjs"
}
USER_RUN_DIR="/run/user/$(id -u)"
Part="--new-session --cap-drop ALL --unshare-user-try --unshare-pid --unshare-cgroup-try --die-with-parent \
    --symlink usr/lib /lib \
    --symlink usr/lib64 /lib64 \
    --ro-bind /usr /usr \
    --ro-bind /usr/bin/flatpak-xdg-open /usr/bin/xdg-open \
    --ro-bind /usr/bin/kdialog /bin/kdialog  \
    --ro-bind /usr/bin/ffmpeg /bin/kdialog  \
    --ro-bind /usr/bin/ffprobe /bin/ffprobe  \
    --ro-bind /usr/bin/bash /bin/bash \
    --ro-bind /usr/bin/zsh /bin/sh \
    --ro-bind /etc/ld.so.cache /etc/ld.so.cache \
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
    --proc /proc \
    --dev-bind /run/dbus /run/dbus \
    --ro-bind-try /etc/fonts /etc/fonts \
    --dev-bind /tmp /tmp \
    --tmpfs ${HOME}/.config/QQ \
    --bind "${USER_RUN_DIR}" "${USER_RUN_DIR}" \
    --bind "${QQ_APP_DIR}" "${QQ_APP_DIR}" \
    --ro-bind-try "${FONTCONFIG_HOME}" "${FONTCONFIG_HOME}" \
    --tmpfs /dev/shm  \
    --ro-bind-try "${XDG_CONFIG_HOME}/gtk-3.0" "${XDG_CONFIG_HOME}/gtk-3.0" \
    --setenv ELECTRON_RUN_AS_NODE 1 \
    --setenv IBUS_USE_PORTAL 1 \
    --setenv APPDIR ${APPDIR} \
    ${NCqq} \
    ${APPDIR}/qq ${QQ_APP_DIR}/resources/app/NapCat/napcat.cjs ${CMD#* }"
    #strace -y -o /tmp/logs/log
bwrap `echo $Part`
rm -rf /tmp/NCQQ
