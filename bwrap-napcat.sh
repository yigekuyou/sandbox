#!/usr/bin/zsh

USER_RUN_DIR="/run/user/$(id -u)"
XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

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
rm /tmp/NCQQ/${QQdir##*\/}
rm -rf ${QQ_APP_DIR}/resources/app/fonts
rm -f ${QQ_APP_DIR}/resources/app/{libssh2.so.1,libunwind*,sharp-lib/libvips-cpp.so.42}

touch /tmp/NCQQ/log
FIFO="/tmp/NCQQ/squashfs-root/resources/app/NapCat/qrcode.png"

if [[ -d "${LOAD}" ]] {
mkdir ${QQ_APP_DIR}/resources/app/NapCat
NCqq="--ro-bind $LOAD/package.json ${QQ_APP_DIR}/resources/app/NapCat/package.json \
--ro-bind $LOAD/node_modules ${QQ_APP_DIR}/resources/app/NapCat/node_modules \
--dev-bind $LOAD/config ${QQ_APP_DIR}/resources/app/NapCat/config \
--ro-bind $LOAD/napcat.cjs ${QQ_APP_DIR}/resources/app/NapCat/napcat.cjs"
}
USER_RUN_DIR="/run/user/$(id -u)"
Part="--clearenv --new-session --cap-drop ALL --unshare-user-try --unshare-pid --unshare-cgroup-try --die-with-parent \
    --symlink usr/lib /lib \
    --symlink usr/lib64 /lib64 \
    --ro-bind /usr /usr \
    --ro-bind /usr/bin/ffprobe /bin/ffprobe  \
    --ro-bind /usr/bin/bash /bin/bash \
    --ro-bind /usr/bin/zsh /bin/sh \
    --ro-bind /etc/ld.so.cache /etc/ld.so.cache \
    --ro-bind-try /etc/fonts /etc/fonts \
    --dev-bind /dev /dev \
    --ro-bind /sys /sys \
    --ro-bind /etc/passwd /etc/passwd \
    --ro-bind-try /run/systemd/userdb /run/systemd/userdb \
    --ro-bind /etc/resolv.conf /etc/resolv.conf \
    --ro-bind /etc/localtime /etc/localtime \
    --proc /proc \
    --ro-bind-try /etc/fonts /etc/fonts \
    --dev-bind /tmp /tmp \
    --tmpfs ${HOME}/.config/QQ \
    --bind "${QQ_APP_DIR}" "${QQ_APP_DIR}" \
    --tmpfs /dev/shm  \
    --setenv ELECTRON_RUN_AS_NODE 1 \
    --setenv APPDIR ${APPDIR} \
    ${NCqq} \
    ${APPDIR}/qq ${QQ_APP_DIR}/resources/app/NapCat/napcat.cjs ${CMD#* }"
    #strace -y -o /tmp/logs/log
(timeout 30 tail -f -n0 /tmp/NCQQ/log |grep -q "qrcode.png"  && xdg-open $FIFO && ) &
bwrap `echo $Part` >/tmp/NCQQ/log
rm -rf /tmp/NCQQ
