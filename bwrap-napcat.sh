#!/usr/bin/zsh
USER_RUN_DIR="/run/user/$(id -u)"
XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# 你猜猜看
NCQQ=/tmp/NCQQ
QQ_APP_DIR=${NCQQ}/squashfs-root
APPDIR=${QQ_APP_DIR}
napcatQQ=${QQ_APP_DIR}/resources/app/NapCat


function command_exists() {
	local command="$1"
	command -v "${command}" >/dev/null 2>&1
}

LOAD=$(realpath $(dirname $(readlink -f $0)) )
CMD=$*
QQdir=${CMD%% *}
# 获取登录图片的方法
LOG=${NCQQ}/log

# 暂存日志
if  [[ ${DEBUG} ]] {
DEBUGLOG=/tmp/logs/QQ-diagnostic
if command_exists strace ;then
DEBUGCMD="/usr/bin/strace -y -o ${DEBUGLOG}"
fi
LOG=/tmp/logs/QQ-log
}


if [[ ${${CMD##* }##*\.} == AppImage ]] {
#	别动 不然启动后缀出现两次
	unset CMD
	}
#	下面请随意
if [[  ${QQdir##*\.} != AppImage ]] {
echo "only name./AppImage"
return -1
}
# 你也不想没有clear env吧
trap 'rm -rf ${NCQQ} ; return -1' INT TERM
# 挂载哪些能保存登录信息而不受垃圾影响

mkdir ${NCQQ}
chmod 700 ${NCQQ}
cp $QQdir ${NCQQ}
cd ${NCQQ}
chmod +x ${NCQQ}/${QQdir##*\/}
./${QQdir##*\/} --appimage-extract > /dev/null
rm ${NCQQ}/${QQdir##*\/}
rm -rf ${QQ_APP_DIR}/resources/app/fonts
rm -f ${QQ_APP_DIR}/resources/app/{libssh2.so.1,libunwind*,sharp-lib/libvips-cpp.so.42}

if [[ -d "${LOAD}" ]] {
touch ${LOG}
FIFO="${napcatQQ}/qrcode.png"
mkdir ${napcatQQ}
NCqq="--ro-bind $LOAD/package.json ${napcatQQ}/package.json \
--ro-bind $LOAD/node_modules ${napcatQQ}/node_modules \
--dev-bind $LOAD/config ${napcatQQ}/config \
--ro-bind $LOAD/napcat.cjs ${napcatQQ}/napcat.cjs"
}
USER_RUN_DIR="/run/user/$(id -u)"
#	这是我的一小步
Part="--new-session --cap-drop ALL --unshare-user-try --unshare-pid --unshare-cgroup-try --die-with-parent \
	--symlink usr/lib /lib \
	--symlink usr/lib64 /lib64 \
	--ro-bind /usr /usr \
	--ro-bind /usr/bin/ffprobe /bin/ffprobe  \
	--ro-bind /usr/bin/zsh /bin/sh \
	--dev-bind /dev /dev \
	--ro-bind /sys /sys \
	--ro-bind /etc/vulkan /etc/vulkan \
	--ro-bind-try /etc/fonts /etc/fonts \
	--ro-bind /etc/ld.so.cache /etc/ld.so.cache \
	--ro-bind /etc/machine-id /etc/machine-id \
	--ro-bind /etc/nsswitch.conf /etc/nsswitch.conf \
	--ro-bind /etc/passwd /etc/passwd \
	--ro-bind-try /run/systemd/userdb /run/systemd/userdb \
	--ro-bind /etc/resolv.conf /etc/resolv.conf \
	--ro-bind /etc/localtime /etc/localtime \
	--tmpfs /dev/shm  \
	--proc /proc \
	--dev-bind /tmp /tmp \
	--tmpfs ${HOME}/.config/QQ \
	--bind "${QQ_APP_DIR}" "${QQ_APP_DIR}" \
	--tmpfs /dev/shm  \
	--setenv ELECTRON_RUN_AS_NODE 1 \
	--setenv  PATH  /bin \
	--setenv APPDIR ${APPDIR} \
	${NCqq} \
	${DEBUGCMD} ${APPDIR}/qq  ${napcatQQ}/napcat.cjs ${CMD#* }"
	#子进程监听任务
(timeout 30 tail -f -n0 ${LOG} |grep -q "qrcode.png"  && xdg-open $FIFO &&timeout 120 tail -f -n0 ${LOG} |grep -q "onQRCodeSessionFailed 1"&&pkill -9 -P $$ ) &

# 主进程
(bwrap `echo $Part` &>${LOG}) &
tail -f -n0 ${LOG} |grep -q "FATAL ERROR"&&pkill -9 -P $$
rm -rf  ${NCQQ}
return 0
