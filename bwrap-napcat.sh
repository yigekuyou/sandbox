#!/usr/bin/zsh
APP_NAME=com.nc.QQ
APP_FOLDER="$XDG_RUNTIME_DIR/app/$APP_NAME"
XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# 你猜猜看
LOAD=$(realpath $(dirname $(readlink -f $0)) )
CMD=$*
QQdir=${CMD%% *}
NCQQ=/tmp/NCQQ
QQ_APP_DIR=${NCQQ}/squashfs-root
APPDIR=${QQ_APP_DIR}
napcatQQ=${QQ_APP_DIR}/resources/app/NapCat${QQ}

keyname=AppImage
	if [[ ${${CMD##* }##*\.} == ${keyname} ]] {
	#别动 不然启动后缀出现两次
	unset CMD
	}

# 环境问题
if [[ ! -d "${NCQQ}" ]] {
# 从一大串arg提取key
	#下面请随意
	if [[  ${QQdir##*\.} != ${keyname} ]] {
	echo "only name./AppImage"
	return -1
	}
trap "rm -rf ${NCQQ} $APP_FOLDE ;return -1" INT
mkdir ${NCQQ}
chmod 700 ${NCQQ}
cp $QQdir ${NCQQ}
cd ${NCQQ}
chmod +x ${NCQQ}/${QQdir##*\/}
./${QQdir##*\/} --appimage-extract > /dev/null
rm ${NCQQ}/${QQdir##*\/}
rm -rf ${QQ_APP_DIR}/resources/app/fonts
rm -rf ${QQ_APP_DIR}/{usr/lib,libEGL.so,libGLESv2.so,libvk_swiftshader.so,libvulkan.so.*}
rm -f ${QQ_APP_DIR}/resources/app/{libssh2.so.1,libunwind*,sharp-lib/libvips-cpp.so.42}
	mkdir -p "$APP_FOLDER"
	echo "[Application]
name=$APP_NAME" > ${QQ_APP_DIR}/flatpak-info
}
function command_exists() {
	local command="$1"
	command -v "${command}" >/dev/null 2>&1
}

# 获取登录图片的方法
LOG=${NCQQ}/${QQ}/QQ/QQ${QQ}.log

# 别扫码了
if [[ ${QQ} ]] {
QQlogin="-q ${QQ}"
[[ ! -e ${LOAD}/config/onebot11_${QQ}.json ]] && cp ${LOAD}/config/onebot11.json ${LOAD}/config/onebot11_${QQ}.json

# 挂载login垃圾时刻
LOGIN=${NCQQ}/${QQ}/QQ
if [[ ! -d ${LOGIN} ]] {
mkdir -p ${LOGIN}
}
msfConfig="--dev-bind ${LOGIN} ${HOME}/.config/QQ --ro-bind ${LOAD}/config/napcat.json ${napcatQQ}/config/napcat.json  "


# 	debug喽
	 grep \"consoleLogLevel\"\:\ \"debug\" ${LOAD}/config/napcat.json &&DEBUG=1

	QQconfig="--ro-bind ${LOAD}/config/onebot11_${QQ}.json ${napcatQQ}/config/onebot11_${QQ}.json \
	 ${msfConfig} \
	"
	trap "rm -rf ${napcatQQ} ${NCQQ}/${QQ}/crash_files ; return -1"  TERM HUP INT
} else { QQconfig="--dev-bind ${LOAD}/config ${napcatQQ}/config"
trap "rm -rf ${napcatQQ} ${NCQQ}/QQ ; return -1"  TERM HUP INT
}
# 暂存日志 记得打开配置的debug
if  [[ ${DEBUG} ]] {
DEBUGLOG=/tmp/logs/QQ${QQ}-diagnostic
if command_exists strace ;then
DEBUGCMD="/usr/bin/strace -y -o ${DEBUGLOG}"
fi
LOG=/tmp/logs/QQ${QQ}.log
}
# 初始化
touch ${LOG}


# 不是哥们 没这个就会死
if [[ -d "${LOAD}/node_modules" ]] {
FIFO="${napcatQQ}/qrcode.png"
mkdir ${napcatQQ}
NCqq="--ro-bind $LOAD/package.json ${napcatQQ}/package.json \
${QQconfig} \
--ro-bind $LOAD/node_modules ${napcatQQ}/node_modules \
--ro-bind $LOAD/napcat.cjs ${napcatQQ}/napcat.cjs"
} else {
echo 提醒需要把启动脚本放入napcat的根目录 \n
[[ -e ${LOAD}/README.md ]]&&echo "还是说没有node_modules？ \n 帮你打开看看" &&xdg-open ${LOAD}/README.md
return -1
}

#	这是我的一小步
Part="--unshare-all --share-net --new-session --die-with-parent \
	--symlink usr/lib /lib \
	--symlink usr/lib64 /lib64 \
	--ro-bind /usr /usr \
	--ro-bind /usr/bin/ffprobe /bin/ffprobe  \
	--ro-bind /usr/bin/ffmpeg /bin/ffmpeg  \
	--ro-bind /usr/bin/bash /bin/sh \
	--ro-bind /sys /sys \
	--dev-bind /dev /dev \
	--ro-bind /etc/vulkan /etc/vulkan \
	--ro-bind-try /etc/fonts /etc/fonts \
	--ro-bind /etc/ld.so.cache /etc/ld.so.cache \
	--ro-bind /etc/machine-id /etc/machine-id \
	--ro-bind /etc/nsswitch.conf /etc/nsswitch.conf \
	--ro-bind /etc/passwd /etc/passwd \
	--ro-bind-try /run/systemd/userdb /run/systemd/userdb \
	--ro-bind /etc/resolv.conf /etc/resolv.conf \
	--ro-bind /etc/localtime /etc/localtime \
	--ro-bind ${QQ_APP_DIR}/flatpak-info "/.flatpak-info" \
	--tmpfs /dev/shm  \
	--proc /proc \
	--dev-bind /tmp /tmp \
	--bind "${QQ_APP_DIR}" "${QQ_APP_DIR}" \
	--tmpfs /dev/shm  \
	--setenv ELECTRON_RUN_AS_NODE 1 \
	--setenv  PATH  /bin \
	--setenv APPDIR ${APPDIR} \
	${NCqq} \
	-- sh -c \" echo \$\$ > ${HOME}/.config/QQ/pid && ${DEBUGCMD} ${APPDIR}/qq  ${napcatQQ}/napcat.cjs ${QQlogin} ${CMD#* } \"  "
	#子进程监听任务
# set_up_dbus_proxy &
(timeout 30 tail -f -n0 ${LOG} |grep -q "qrcode.png"  && xdg-open $FIFO &&timeout 120 tail -f -n0 ${LOG} |grep -q "onQRCodeSessionFailed 1"&&pkill -15 -P $$ ) &
# 主进程
echo $Part|xargs bwrap  &>${LOG} ;pkill -TERM -P $$
