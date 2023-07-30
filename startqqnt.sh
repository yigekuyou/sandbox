#!/usr/bin/zsh
CMD=$*
QQdir=${CMD%% *}
if [[ ${${CMD##* }##*\.} == appimage ]] {
    unset CMD
    }
if [[  ${QQdir##*\.} != appimage ]] {
echo "only name./appimage"
return -1
}
USER_RUN_DIR="/run/user/$(id -u)"
trap 'rm -rf /tmp/QQ ; return 0' INT TERM
mkdir /tmp/QQ
chmod 700 /tmp/QQ
cp $QQdir /tmp/QQ
cd /tmp/QQ
chmod +x /tmp/QQ/${QQdir##*\/}
./${QQdir##*\/} --appimage-extract > /dev/null
rm -f /tmp/QQ/${QQdir##*\/}
if [[ -z "${QQ_DOWNLOAD_DIR}" ]] {
    if [[ -z "${XDG_DOWNLOAD_DIR}" ]] {
        XDG_DOWNLOAD_DIR="$(xdg-user-dir DOWNLOAD)"
        }
    QQ_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
    }
QQ_APP_DIR=/tmp/QQ/squashfs-root
APPDIR=${QQ_APP_DIR}
bwrap --new-session --cap-drop ALL --unshare-user-try --unshare-pid --unshare-cgroup-try --die-with-parent \
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
    --bind-try "${HOME}/.pki" "${HOME}/.pki" \
    --bind "${USER_RUN_DIR}" "${USER_RUN_DIR}" \
    --ro-bind-try "${XAUTHORITY}" "${XAUTHORITY}" \
    --bind-try "${QQ_DOWNLOAD_DIR}" "${QQ_DOWNLOAD_DIR}" \
    --bind "${QQ_APP_DIR}" "${QQ_APP_DIR}" \
    --tmpfs /dev/shm  \
    --ro-bind-try "${HOME}/.icons" "${HOME}/.icons" \
    --ro-bind-try "${HOME}/.local/share/.icons" "${HOME}/.local/share/.icons" \
    --ro-bind-try "${XDG_CONFIG_HOME}/gtk-3.0" "${XDG_CONFIG_HOME}/gtk-3.0" \
    --setenv IBUS_USE_PORTAL 1 \
    --setenv APPDIR ${APPDIR} \
    ${APPDIR}/AppRun ${CMD##* }
rm -rf /tmp/QQ
