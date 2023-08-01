#!/usr/bin/zsh
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
 if [[ -d "${LOAD}" ]] {
 LiteLoader="--ro-bind $LOAD ${QQ_APP_DIR}/resources/app/LiteLoader \
    --tmpfs ${QQ_APP_DIR}/resources/app/LiteLoader/data \
    --dev-bind $LOAD/$data/plugins ${QQ_APP_DIR}/resources/app/LiteLoader/data/plugins \
    --dev-bind $LOAD/$data/plugins_data ${QQ_APP_DIR}/resources/app/LiteLoader/data/plugins_data \
    --dev-bind $LOAD/$data/config.json ${QQ_APP_DIR}/resources/app/LiteLoader/data/config.json \
    --ro-bind /etc/ssl /etc/ssl \
    --setenv LITELOADERQQNT_PROFILE ${QQ_APP_DIR}/resources/app/LiteLoader/data"
 sed -i 's|"main": "./app_launcher/index.js"|"main": "LiteLoader"|g' ${QQ_APP_DIR}/resources/app/package.json
    }

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
    --symlink usr/bin /bin \
    --ro-bind /usr /usr \
    --ro-bind /etc/machine-id /etc/machine-id \
    --dev-bind /dev /dev \
    --ro-bind /sys /sys \
    --ro-bind /etc/passwd /etc/passwd \
    --ro-bind /etc/resolv.conf /etc/resolv.conf \
    --ro-bind /etc/localtime /etc/localtime \
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
    ${LiteLoader}  \
    --ro-bind-try "${XAUTHORITY}" "${XAUTHORITY}" \
    ${APPDIR}/AppRun ${CMD#* }"
echo ${Part} |xargs bwrap
rm -rf /tmp/QQ
