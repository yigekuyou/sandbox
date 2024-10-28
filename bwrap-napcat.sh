#!/usr/bin/zsh
APP_NAME=com.nc.QQ
APP_FOLDER="$XDG_RUNTIME_DIR/app/$APP_NAME"
XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# 你猜猜看
PWD=$(realpath $(dirname $(readlink -f $0)) )
CMD=$*
QQdir=${CMD%% *}
NCQQ=/tmp/NCQQ
QQ_APP_DIR=${NCQQ}/squashfs-root
APPDIR=${QQ_APP_DIR}
napcatQQ=${QQ_APP_DIR}/resources/app/app_launcher/NapCat${QQ}

keyname=AppImage
	if [[ ${${CMD##* }##*\.} == ${keyname} ]] {
	#别动 不然启动后缀出现两次
	unset CMD
	}
function get_system_arch() {
    echo $(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)
}
system_arch=$(get_system_arch)
function get_qq() {
    response=$( curl -s "https://nclatest.znin.net/get_qq_ver" )
    remoteQQVer=$( echo "$response" | jq -r '.linuxVersion' )
    remoteQQVerHash=$( echo "$response" | jq -r '.linuxVerHash' )
    echo "$remoteQQVer $remoteQQVerHash"

    base_url="https://dldir1.qq.com/qqfile/qq/QQNT/$remoteQQVerHash/linuxqq_$remoteQQVer"
    if [ "$system_arch" = "amd64" ]; then
            qq_download_url="${base_url}_x86_64.AppImage"
    elif [ "$system_arch" = "arm64" ]; then
            qq_download_url="${base_url}_arm64.AppImage"
    fi

curl -L "$qq_download_url" -o ${NCQQ}/linuxqq.AppImage
cp ${NCQQ}/linuxqq.AppImage $HOME/.cache

}
# 环境问题
LOAD=$HOME/.config/$APP_NAME
if [[ ! -d "${LOAD}/config" ]] {
mkdir -p ${LOAD}/config
}
NapCat=$HOME/.local/share/$APP_NAME
if [[ ! -d "${NapCat}" ]] {
mkdir -p ${NapCat}
}
if [[ ! -d "${QQ_APP_DIR}" ]] {
# 从一大串arg提取key
trap "rm -rf ${NCQQ} $APP_FOLDE ;return -1" INT
mkdir -p ${QQ_APP_DIR}
mkdir -p ${NCQQ}/NapCat.Shell
chmod 700 ${NCQQ}
cd ${NCQQ}
	if [[  ${QQdir##*\.} != ${keyname} ]] {
	echo "only name./AppImage"
	QQdir=$HOME/.cache/linuxqq.AppImage
	if [[ ! -e "${QQdir}" ]] {
	get_qq
	} else { cp $QQdir ${NCQQ} }
linuxNameQQ=linuxqq.AppImage
	} else {
	linuxNameQQ=${QQdir##*\/}
	cp $QQdir ${NCQQ}
}
chmod +x ${NCQQ}/$linuxNameQQ
./$linuxNameQQ --appimage-extract > /dev/null
rm ${NCQQ}/$linuxNameQQ
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
[[ ! -e ${LOAD}/config/napcat_${QQ}.json ]] && cp ${LOAD}/config/napcat.json ${LOAD}/config/napcat_${QQ}.json
[[ ! -e ${LOAD}/config/webui.json ]] && echo '{
    "host": "0.0.0.0",
    "port": 0,
    "prefix": "",
    "token": "0",
    "loginRate": 0
}' > ${LOAD}/config/webui.json
# 挂载login垃圾时刻
LOGIN=${NCQQ}/${QQ}/QQ
if [[ ! -d ${LOGIN} ]] {
mkdir -p ${LOGIN}
}
if [[ ! -d ${napcatQQ}/cache ]] {
mkdir -p ${napcatQQ}/cache
}
msfConfig="--dev-bind ${LOGIN} ${HOME}/.config/QQ --ro-bind ${LOAD}/config/napcat.json ${napcatQQ}/config/napcat.json  "

	QQconfig="--ro-bind  ${LOAD}/config/napcat_${QQ}.json ${napcatQQ}/config/napcat_${QQ}.json  \
	--ro-bind ${LOAD}/config/onebot11_${QQ}.json ${napcatQQ}/config/onebot11_${QQ}.json \
	 ${msfConfig} \
	--dev-bind ${LOAD}/config/webui.json ${napcatQQ}/config/webui.json "
	trap "rm -rf ${napcatQQ} ${NCQQ}/${QQ}/crash_files $NCQQ/NapCat ; return -1"  TERM HUP INT
} else { QQconfig="--dev-bind ${LOAD}/config ${napcatQQ}/config"
trap "rm -rf ${napcatQQ} $NCQQ/NapCat ${NCQQ}/QQ ; return -1"  TERM HUP INT
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

function get_napcat() {
napcat_version=$(curl "https://nclatest.znin.net/" | jq -r '.tag_name')
        proxy_arr=("https://ghp.ci" "https://github.moeyy.xyz" "https://mirror.ghproxy.com" "https://gh-proxy.com" "https://x.haod.me")
        check_url="https://raw.githubusercontent.com/NapNeko/NapCatQQ/main/package.json"
            for proxy in "${proxy_arr[@]}"; do
                 network=$(curl -o /dev/null -s -w "%{http_code}" "$proxy/$check_url")
                if  [ $network -eq 200 ]; then
                    found=1
                    target_proxy="$proxy"
                    break
                fi
            done

            if [ $found -eq 0 ]; then
                exit 1
            fi

    napcat_download_url="${target_proxy:+${target_proxy}/}https://github.com/NapNeko/NapCatQQ/releases/download/$napcat_version/NapCat.Shell.zip"

    if [ "$system_arch" = "amd64" ]; then
        napcat_dlc_download_url="${target_proxy:+${target_proxy}/}https://github.com/NapNeko/NapCatQQ/releases/download/$napcat_version/napcat.packet.linux"
    elif [ "$system_arch" = "arm64" ]; then
        napcat_dlc_download_url="${target_proxy:+${target_proxy}/}https://github.com/NapNeko/NapCatQQ/releases/download/$napcat_version/napcat.packet.arm64"
    fi
mkdir ${NCQQ}/napcat.packet
curl -L "$napcat_dlc_download_url" -o ${NCQQ}/napcat.packet/packet

curl -L "$napcat_download_url" -o ${NCQQ}/NapCat.Shell.zip

chmod +x ${NCQQ}/napcat.packet/packet
unzip -q -o -d ${NCQQ}/NapCat.Shell ${NCQQ}/NapCat.Shell.zip
pushd  NapCat.Shell
tar -cvf -node_modules  napcat.mjs package.json | zstd -T0 > $NapCat/NapCat.tar.zst
popd
cp -rp ${NCQQ}/napcat.packet/packet $NapCat/packet
}
rm -rf NapCat
if [[ -e "$NapCat/NapCat.tar.zst" ]] {
mkdir -p ${NCQQ}/NapCat
cp $NapCat/NapCat.tar.zst ${NCQQ}/NapCat
pushd ${NCQQ}/NapCat
zstd -d NapCat.tar.zst
tar -xf NapCat.tar
popd
} else {
get_napcat
mv ${NCQQ}/NapCat.Shell ${NCQQ}/NapCat
}
function updatenapcat() {
napcat_version=$(curl "https://nclatest.znin.net/" | jq -r '.tag_name')
if [ -z $napcat_version ]; then
    echo "无法获取NapCatQQ版本, 请检查错误。"
    exit 1
fi
echo "最新NapCatQQ版本: $napcat_version"
target_folder="${NCQQ}/NapCat"
    if [ -d "${NCQQ}/NapCat" ]; then
        current_version=$(jq -r '.version' "${NCQQ}/NapCat/package.json")
        echo "NapCatQQ已安装, 版本: v$current_version"
        target_version=${napcat_version#v}
        IFS='.' read -r i1 i2 i3 <<< "$current_version"
        IFS='.' read -r t1 t2 t3 <<< "$target_version"
        if (( i1 < t1 || (i1 == t1 && i2 < t2) || (i1 == t1 && i2 == t2 && i3 < t3) )); then
            get_napcat
        else
            echo "已安装最新版本, 无需更新。"
        fi
    fi
}
mkdir ${napcatQQ}
NCqq="--ro-bind ${NCQQ}/NapCat/package.json ${napcatQQ}/package.json \
${QQconfig} \
--ro-bind ${NCQQ}/NapCat/node_modules ${napcatQQ}/node_modules \
--ro-bind ${NCQQ}/NapCat/napcat.mjs ${napcatQQ}/napcat.mjs"
	echo "(async () => {await import('file:///${napcatQQ}/napcat.mjs');})();" >${napcatQQ}/index.js
jq --arg jsPath loadNapCat.js \
    '.main = $jsPath' "${QQ_APP_DIR}/resources/app/package.json" > ${napcatQQ}/tmp

set_up_packet() {
	bwrap \
	--new-session \
	--ro-bind /lib64 /lib64 \
	--tmpfs /bin \
	--tmpfs /tmp \
	--ro-bind $NapCat/packet /bin/packet \
	--die-with-parent \
	-- /bin/packet }
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
	--ro-bind /usr/share/vulkan /usr/share/vulkan \
	--ro-bind-try /etc/fonts /etc/fonts \
	--ro-bind /etc/ld.so.cache /etc/ld.so.cache \
	--ro-bind /etc/machine-id /etc/machine-id \
	--ro-bind /etc/nsswitch.conf /etc/nsswitch.conf \
	--ro-bind /etc/passwd /etc/passwd \
	--ro-bind-try /run/systemd/userdb /run/systemd/userdb \
	--ro-bind /etc/resolv.conf /etc/resolv.conf \
	--ro-bind /etc/localtime /etc/localtime \
	--dev-bind ${napcatQQ}/cache ${napcatQQ}/cache \
	--ro-bind ${QQ_APP_DIR}/flatpak-info "/.flatpak-info" \
	--ro-bind ${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY} ${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY} \
	--tmpfs /dev/shm  \
	--proc /proc \
	--dev-bind /tmp /tmp \
	--bind "${QQ_APP_DIR}" "${QQ_APP_DIR}" \
	--ro-bind ${napcatQQ}/index.js ${QQ_APP_DIR}//resources/app/loadNapCat.js \
	--ro-bind ${napcatQQ}/tmp ${QQ_APP_DIR}//resources/app/package.json  \
	--tmpfs /dev/shm  \
	--unsetenv SESSION_MANAGER \
	--setenv  PATH  /bin \
	--setenv ELECTRON_OZONE_PLATFORM_HINT auto \
	--setenv ELECTRON_RUN_AS_NODE 1 \
	--setenv APPDIR ${APPDIR} \
	${NCqq} \
	-- sh -c \"${DEBUGCMD} ${APPDIR}/qq --no-sandbox ${napcatQQ}/napcat.mjs   ${QQlogin} ${CMD#* }  \"  "
	#子进程监听任务
set_up_packet &
sleep 1
(timeout 30 tail -f -n0 ${LOG} |grep "qrcode" |awk '{print $7}' | xargs xdg-open) &
# 主进程
echo $Part|xargs bwrap  &>${LOG} ;pkill -TERM -P $$
