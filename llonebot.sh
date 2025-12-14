#!/usr/bin/zsh
APP_NAME=com.qq.QQ.llonebot

APP_FOLDER="$XDG_RUNTIME_DIR/app/$APP_NAME"
XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
FONTCONFIG_HOME="${XDG_CONFIG_HOME}/fontconfig"
XMODIFIERS=@im=fcitx
curlproxy=127.0.0.1:17200

function command_exists() {
	local command="$1"
	command -v "${command}" >/dev/null 2>&1
}

if [[ ! -v $XDG_DATA_HOME ]]; then
    XDG_DATA_HOME=$HOME/.local/share
elif [[ -z "$XDG_DATA_HOME" ]]; then
    XDG_DATA_HOME=$HOME/.local/share
else

fi


LOADONEBOT=$(dirname $(readlink -f $0))/LLOneBot.tar.zst
LOADONEBOTDIR=$(dirname $(readlink -f $0))
if [[ ! -f "${LOADONEBOT}" ]] {
LOADONEBOT=$XDG_DATA_HOME/LLOneBot/LLOneBot.tar.zst
LOADONEBOTDIR=$XDG_DATA_HOME/LLOneBot
if [[ ! -f "$LOADONEBOTDIR" ]] { mkdir -p $LOADONEBOTDIR }

}
if [[ ! -f ${HOME}/.config/LLOneBot ]] { mkdir -p ${HOME}/.config/LLOneBot }

if [[ ! -f ${HOME}/.cache/LLOneBot/data/database ]] { mkdir -p ${HOME}/.cache/LLOneBot/data/database }


# 驻波缓存
QQ_APP_ROOTDIR=/tmp/QQ/
LOGIN=${QQ_APP_ROOTDIR}/$APP_NAME

QQ_APP_DIR=${QQ_APP_ROOTDIR}/squashfs-root
APPDIR=${QQ_APP_DIR}
CMD=$*
QQdir=${CMD%% *}

function get_system_arch() { echo $(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) }
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

curl -L "$qq_download_url" -o ${QQ_APP_ROOTDIR}/linuxqq.AppImage
mv ${QQ_APP_ROOTDIR}/linuxqq.AppImage $HOME/.cache
}
# 环境问题
if [[ ! -d ${LOGIN} ]] {
mkdir -p  ${LOGIN}
chmod 700 ${LOGIN}
}

keyname=AppImage
	if [[ ${${CMD##* }##*\.} == ${keyname} ]] {
	#别动 不然启动后缀出现两次
	unset CMD
}

if [[ ! -d "${APP_FOLDER}" ]] {
mkdir -p ${APP_FOLDER}
}

if [[ ! -d "${QQ_APP_DIR}" ]] {
# 从一大串arg提取key

	#下面请随意
	if [[  ${QQdir##*\.} != ${keyname} ]] {
	echo "only name./AppImage"
	QQdir=$HOME/.cache/linuxqq.AppImage
	}
	if [[ ! -f "${QQdir}" ]] {
		QQdir=$HOME/.cache/linuxqq.AppImage
	}
	if [[ ! -f "${QQdir}" ]] {
		get_qq
	}
	trap "rm -rf ${QQ_APP_DIR}  ;return -1"INT
	cp $QQdir ${QQ_APP_ROOTDIR}
	cd ${QQ_APP_ROOTDIR}
	chmod +x ${QQ_APP_ROOTDIR}/${QQdir##*\/}
	./${QQdir##*\/} --appimage-extract > /dev/null
	rm ${QQ_APP_ROOTDIR}/${QQdir##*\/}

	rm -rf ${QQ_APP_DIR}/resources/app/fonts
	rm -f ${QQ_APP_DIR}/resources/app/{libssh2.so.1,libunwind*,sharp-lib/libvips-cpp.so.42}
	rm -rf ${QQ_APP_DIR}/{usr/lib,libvulkan.so.1,libvk_swiftshader.so}
	echo "[Application]
name=com.qq.QQ" > ${QQ_APP_DIR}/flatpak-info
}


trap "exit -1" INT



setopt no_nomatch
	function get_llonebot() {
		mkdir -p ${QQ_APP_ROOTDIR}/LLOneBot/
		orgin=https://github.com/LLOneBot/LLOneBot.git
		# versions=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' $orgin | tail --lines=1 | cut --delimiter='/' --fields=3|cut --delimiter='^' --fields=1)
		rm -rf ${QQ_APP_ROOTDIR}/LLOneBot/*

		[[ $curlproxy ]]&&export https_proxy=$curlproxy
		download="https://github.com/LLOneBot/LuckyLilliaBot/releases/download/v$versions/LLBot-CLI-linux-$(arch | sed s/aarch64/arm64/ | sed s/x86_64/x64/).zip"
		echo $download
		curl -L $download -o ${QQ_APP_ROOTDIR}/LLOneBot.zip &&echo 1 > ${QQ_APP_ROOTDIR}/ok
		unset https_proxy
		for ((i = 2; i=1;i++  )); do if [[ -f ${QQ_APP_ROOTDIR}/ok ]] i=0 &&rm ${QQ_APP_ROOTDIR}/ok &&break;sleep 1; done


		unzip -q -o -d ${QQ_APP_ROOTDIR}/LLOneBot ${QQ_APP_ROOTDIR}/LLOneBot.zip
		rm ${QQ_APP_ROOTDIR}/LLOneBot.zip
		pushd  ${QQ_APP_ROOTDIR}/LLOneBot/llbot
		jq  '.webui.enable=false|.log=false' default_config.json > ../default_config.json
		chmod +x {pmhq,node}
		tar -cf - pmhq node node_modules ../default_config.json llonebot.js llonebot.js.map package.json| zstd -T0 > ${QQ_APP_ROOTDIR}/LLOneBot.tar.zst
		cd ../
		zstd -d ${QQ_APP_ROOTDIR}/LLOneBot.tar.zst -o LLOneBot.tar
		tar -xf LLOneBot.tar
		popd
		mv ${QQ_APP_ROOTDIR}/LLOneBot.tar.zst ${LOADONEBOTDIR}
	}

	versions_old=0
	if [[ $curlproxy ]] export  https_proxy=$curlproxy;
	echo $https_proxy
	unset https_proxy
	versions=$(curl -L "https://api.github.com/repos/LLOneBot/LuckyLilliaBot/releases" |jq -r '.[0].tag_name'| sed 's/v//')
	for ((i = 2; i=1;i++  )); do if [[ $versions ]] break ;echo $i ;sleep 1; done

	if [[ ! -e ${QQ_APP_ROOTDIR}/LLOneBot/package.json ]] {
		if [[ -f "${LOADONEBOT}" ]] {
		rm -rf ${QQ_APP_ROOTDIR}/LLOneBot
		mkdir -p ${QQ_APP_ROOTDIR}/LLOneBot
		cp ${LOADONEBOT} ${QQ_APP_ROOTDIR}/LLOneBot/
		pushd ${QQ_APP_ROOTDIR}/LLOneBot
		zstd -d LLOneBot.tar.zst -o LLOneBot.tar
		if ( !  tar -xf LLOneBot.tar ){  get_llonebot }
		if [[ -f package.json ]] {versions_old=`cat package.json |jq -r .version` }
		}
		if [[ $versions_old != $versions ]] {
			get_llonebot
		}
		popd
	}

	Config="${Config} --dev-bind ${QQ_APP_ROOTDIR}/LLOneBot ${QQ_APP_DIR}/LLOneBot"

Wayland="--enable-wayland-ime  --enable-features=WebRTCPipeWireCapturer"
	llonebot() {
	pushd ${HOME}/.cache/LLOneBot/
	bwrap \
	--new-session \
	--tmpfs / \
	--symlink /usr/lib64 /lib64 \
	--ro-bind /usr/lib /usr/lib \
	--ro-bind /usr/lib64 /usr/lib64 \
	--ro-bind /etc/ld.so.cache /etc/ld.so.cache  \
	--ro-bind /usr/bin/ffprobe /bin/ffprobe  \
	--ro-bind /usr/bin/ffmpeg /bin/ffmpeg  \
	--tmpfs $HOME \
	--tmpfs /tmp \
	--dev-bind ${HOME}/.cache/LLOneBot ${HOME}/.cache/LLOneBot \
	--dev-bind ${QQ_APP_ROOTDIR} ${QQ_APP_ROOTDIR} \
	--dev-bind ${LOGIN} ${HOME}/.config/QQ \
	--dev-bind ${QQ_APP_ROOTDIR} ${QQ_APP_ROOTDIR}/../qq \
	--bind /tmp/logs/onebot ${HOME}/.cache/LLOneBot/data/logs \
	--bind /tmp/logs/onebot ${HOME}/.cache/LLOneBot/data/temp \
	--bind ${QQ_APP_ROOTDIR}/LLOneBot/node /usr/bin/node \
	--die-with-parent \
	-- node  ${QQ_APP_ROOTDIR}/LLOneBot/llonebot.js --pmhq-host=127.0.0.1 --pmhq-port=13000
	popd
	}
	set_up_dbus_proxy() {
	bwrap \
	--new-session \
	--symlink /usr/lib64 /lib64 \
	--ro-bind /usr/lib /usr/lib \
	--ro-bind /usr/lib64 /usr/lib64 \
	--ro-bind /usr/bin /usr/bin \
	--bind "$XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR" \
	--ro-bind ${QQ_APP_DIR}/flatpak-info "$XDG_RUNTIME_DIR/.flatpak-info" \
	--die-with-parent \
	-- \
	env -i xdg-dbus-proxy \
	"$DBUS_SESSION_BUS_ADDRESS" \
	"$APP_FOLDER/bus" \
	--filter \
	--own=$APP_NAME \
	--talk=org.freedesktop.portal.Notification.AddNotification \
	--talk=org.kde.StatusNotifierItem \
	--talk=org.freedesktop.DBus.GetNameOwner \
	--talk=org.freedesktop.Notifications \
	--talk=org.kde.StatusNotifierWatcher \
	--talk=org.freedesktop.DBus.NameAcquired \
	--talk=org.freedesktop.portal.Documents \
	--talk=org.freedesktop.portal.Flatpak \
	--talk=org.freedesktop.portal.Desktop \
	--talk=org.freedesktop.portal.FileChooser \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.OpenURI.OpenFile \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.OpenURI.OpenURI \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.ScreenCast.OpenPipeWireRemote \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.Request.Response \
	--see=org.freedesktop.portal.Request.* \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.ScreenCast.CreateSession \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.ScreenCast.Start \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.ScreenCast.SelectSources \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.Session.Close \
	--log &> /tmp/logs/dbus
}
# xauth=`xauth  info |grep ${XDG_RUNTIME_DIR} |awk '{print $3}'`
Part="--new-session --unshare-all --share-net  --die-with-parent \
	--symlink usr/lib /lib \
	--symlink usr/lib64 /lib64 \
	--ro-bind /usr/lib /usr/lib \
	--ro-bind /usr/lib64 /usr/lib64 \
	--ro-bind /usr/bin /usr/bin \
	--ro-bind /usr/bin/flatpak-xdg-open /bin/xdg-open \
	--ro-bind /usr/share /usr/share \
	--ro-bind /usr/bin/bash /bin/bash \
	--ro-bind /usr/bin/zsh /bin/sh \
	--ro-bind /etc/machine-id /etc/machine-id \
	--ro-bind /usr/bin/ffprobe /bin/ffprobe  \
	--ro-bind /usr/bin/ffmpeg /bin/ffmpeg  \
	--ro-bind /etc/nsswitch.conf /etc/nsswitch.conf \
	--ro-bind-try /run/systemd/userdb /run/systemd/userdb \
	--ro-bind /etc/localtime /etc/localtime \
	--ro-bind /etc/resolv.conf /etc/resolv.conf \
	--ro-bind /usr/share/vulkan /usr/share/vulkan \
	--dev-bind /dev/ /dev/ \
	--ro-bind /etc/ld.so.cache /etc/ld.so.cache  \
	--ro-bind-try /etc/fonts /etc/fonts \
	--ro-bind /sys/dev/char /sys/dev/char \
	--ro-bind /sys/devices /sys/devices \
	--ro-bind /sys /sys \
	--ro-bind /etc/passwd /etc/passwd \
	--ro-bind-try /run/systemd/userdb /run/systemd/userdb \
	--ro-bind /etc/localtime /etc/localtime \
	--dev-bind ${LOGIN} ${HOME}/.config/QQ \
	--dev-bind ${HOME}/.config/LLOneBot ${HOME}/.config/LLOneBot \
	--tmpfs ${HOME}/.config/QQ/crash_files \
	--tmpfs ${HOME}/.config/QQ/Crashpad \
	--tmpfs ${HOME}/.config/QQ/versions \
	--bind /tmp/logs/onebot ${HOME}/.cache/LLOneBot/data/temp \
	--proc /proc \
	--ro-bind-try /etc/fonts /etc/fonts \
	--tmpfs /tmp \
	--dev-bind "$APP_FOLDER" "${XDG_RUNTIME_DIR}" \
	--ro-bind ${QQ_APP_DIR}/flatpak-info ${XDG_RUNTIME_DIR}/flatpak-info \
	--ro-bind "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0" \
	--dev-bind ${XDG_RUNTIME_DIR}/doc ${XDG_RUNTIME_DIR}/doc \
	--ro-bind ${XDG_RUNTIME_DIR}/pulse ${XDG_RUNTIME_DIR}/pulse \
	--ro-bind ${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY} ${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY} \
	--ro-bind /lib64/libvulkan.so.1 /opt/QQ/libvulkan.so.1 \
	--dev-bind "${QQ_APP_DIR}" "/opt/QQ" \
	--dev-bind ${QQ_APP_ROOTDIR} ${QQ_APP_ROOTDIR}/../qq \
	--tmpfs /dev/shm  \
	--dev-bind ${QQ_APP_ROOTDIR} ${QQ_APP_ROOTDIR} \
	--ro-bind-try "${XDG_CONFIG_HOME}/gtk-3.0" "${XDG_CONFIG_HOME}/gtk-3.0" \
	--ro-bind ${QQ_APP_ROOTDIR}/LLOneBot/pmhq ${HOME}/.config/LLOneBot/pmhq \
	--ro-bind "$XAUTHORITY" "$XAUTHORITY" \
	--setenv NO_AT_BRIDGE 1 \
	--setenv PATH /bin:/usr/bin \
	--setenv WEBKIT_DISABLE_COMPOSITING_MODE 1 \
	--setenv ELECTRON_OZONE_PLATFORM_HINT auto \
	--setenv APPDIR ${APPDIR} \
	--setenv LD_PRELOAD /lib64/libstdc++.so.6
	${HOME}/.config/LLOneBot/pmhq ${CMD#* } "
	#strace -y -o /tmp/logs/log
set_up_dbus_proxy &
llonebot &>/tmp/logs/llonebot.log &
bwrap `echo $Part` &>  /tmp/logs/lloneQQ.log
pkill -TERM -P $$
