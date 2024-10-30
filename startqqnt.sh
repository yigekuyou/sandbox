#!/usr/bin/zsh
APP_NAME=com.qq.QQ
APP_FOLDER="$XDG_RUNTIME_DIR/app/$APP_NAME"
XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
FONTCONFIG_HOME="${XDG_CONFIG_HOME}/fontconfig"
XMODIFIERS=@im=fcitx

# 驻波缓存
QQ_APP_ROOTDIR=/tmp/QQ
LOGIN=${QQ_APP_ROOTDIR}/${USER}

QQ_APP_DIR=${QQ_APP_ROOTDIR}/squashfs-root
APPDIR=${QQ_APP_DIR}
LOAD=$(dirname $(readlink -f $0))/LiteLoaderQQNT
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

curl -L "$qq_download_url" -o ${NCQQ}/linuxqq.AppImage
mv ${NCQQ}/linuxqq.AppImage $HOME/.cache
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
name=$APP_NAME" > ${QQ_APP_DIR}/flatpak-info

	mkdir ${QQ_APP_DIR}/resources/app/LiteLoader
}


trap "exit -1" INT


function command_exists() {
	local command="$1"
	command -v "${command}" >/dev/null 2>&1
}
setopt no_nomatch
if [[ -d "${LOAD}" ]] {
	{ Config="--dev-bind $LOAD/data/data ${QQ_APP_DIR}/resources/app/LiteLoader/data/data" }
	if [[ -f $LOAD/data/data/LiteLoader/config.json  ]] {
		pushd $LOAD/data/data
		for dir in ./*
			do
			Config="${Config} --tmpfs ${QQ_APP_DIR}/resources/app/LiteLoader/data/data/$dir"
				for file in ./$dir/*
					do
					if [[ -f "$file" ]] {
						Config="${Config} --dev-bind $LOAD/data/data/$file ${QQ_APP_DIR}/resources/app/LiteLoader/data/data/$file"
					} else
					{
						if [[ -d "$file" ]] {
						rm -rf $file
						}
					}
					done
			done
		popd
	} else { Config="--dev-bind $LOAD/data/data ${QQ_APP_DIR}/resources/app/LiteLoader/data/data" }
	LiteLoader="--ro-bind $LOAD/package.json ${QQ_APP_DIR}/resources/app/LiteLoader/package.json \
	--ro-bind $LOAD/src ${QQ_APP_DIR}/resources/app/LiteLoader/src \
	--dev-bind $LOAD/data/plugins ${QQ_APP_DIR}/resources/app/LiteLoader/data/plugins \
	$Config \
	--dev-bind $LOAD/data/config.json ${QQ_APP_DIR}/resources/app/LiteLoader/data/config.json \
	--ro-bind /etc/ssl /etc/ssl \
	--setenv LITELOADERQQNT_PROFILE ${QQ_APP_DIR}/resources/app/LiteLoader/data"
	echo "const fs = require(\"fs\");
	const path = require(\"path\");
	const package_path = path.join(process.resourcesPath, \"app/package.json\");
	const package = require(package_path);
	package.main = \"./application/app_launcher/index.js\";
	fs.writeFileSync(package_path, JSON.stringify(package, null, 4), \"utf-8\");
	require('${QQ_APP_DIR}/resources/app/LiteLoader/');
	require('../major.node').load('internal_index', module);" > ${QQ_APP_DIR}/index.js
jq --arg jsPath app_launcher/index.js \
    '.main = $jsPath' "${QQ_APP_DIR}/resources/app/package.json" > ${QQ_APP_DIR}/package.json
}
Wayland="--enable-wayland-ime  --enable-features=WebRTCPipeWireCapturer"

	set_up_dbus_proxy() {
	bwrap \
	--new-session \
	--symlink /usr/lib64 /lib64 \
	--ro-bind /usr/lib /usr/lib \
	--ro-bind /usr/lib64 /usr/lib64 \
	--ro-bind /usr/bin /usr/bin \
	--bind "$XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR" \
	--ro-bind ${QQ_APP_DIR}/flatpak-info "/.flatpak-info" \
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
	--talk=org.gtk.vfs.Daemon \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.OpenURI.OpenFile \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.OpenURI.OpenURI \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.ScreenCast.OpenPipeWireRemote \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.Request.Response \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.ScreenCast.CreateSession \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.ScreenCast.Start \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.ScreenCast.SelectSources \
	--call=org.freedesktop.portal.Desktop=org.freedesktop.portal.Session.Close \
#   	--log &> /tmp/logs/dbus
	}
xauth=`xauth  info |grep ${XDG_RUNTIME_DIR} |awk '{print $3}'`
Part="--new-session --unshare-all --share-net  --die-with-parent \
	--symlink usr/lib /lib \
	--symlink usr/lib64 /lib64 \
	--ro-bind /usr/lib /usr/lib \
	--ro-bind /usr/lib64 /usr/lib64 \
	--ro-bind /usr/bin /usr/bin \
	--ro-bind /usr/bin/flatpak-xdg-open /usr/bin/xdg-open \
	--ro-bind ${QQ_APP_DIR}/flatpak-info "/.flatpak-info" \
	--ro-bind /usr/share /usr/share \
	--ro-bind /usr/bin/bash /bin/bash \
	--ro-bind /usr/bin/zsh /bin/sh \
	--ro-bind /etc/machine-id /etc/machine-id \
	--ro-bind /etc/nsswitch.conf /etc/nsswitch.conf \
	--ro-bind-try /run/systemd/userdb /run/systemd/userdb \
	--ro-bind /etc/localtime /etc/localtime \
	--ro-bind /etc/resolv.conf /etc/resolv.conf \
	--ro-bind /usr/share/vulkan /usr/share/vulkan \
	--dev-bind /dev/ /dev/ \
	--ro-bind-try /etc/fonts /etc/fonts \
	--ro-bind /sys/dev/char /sys/dev/char \
	--ro-bind /sys/devices /sys/devices \
	--ro-bind /sys /sys \
	--ro-bind /etc/passwd /etc/passwd \
	--ro-bind-try /run/systemd/userdb /run/systemd/userdb \
	--ro-bind /etc/localtime /etc/localtime \
	--dev-bind ${LOGIN} ${HOME}/.config/QQ \
	--tmpfs ${HOME}/.config/QQ/crash_files \
	--tmpfs ${HOME}/.config/QQ/Crashpad \
	--tmpfs ${HOME}/.config/QQ/versions \
	--proc /proc \
	--ro-bind-try /etc/fonts /etc/fonts \
	--dev-bind /tmp /tmp \
	--dev-bind "$APP_FOLDER" "${XDG_RUNTIME_DIR}" \
	--ro-bind-try "${XDG_CONFIG_HOME}/dconf" "${XDG_CONFIG_HOME}/dconf" \
	--ro-bind "${xauth}" "${xauth}" \
	--ro-bind "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0" \
	--dev-bind ${XDG_RUNTIME_DIR}/doc ${XDG_RUNTIME_DIR}/doc \
	--ro-bind ${XDG_RUNTIME_DIR}/pulse ${XDG_RUNTIME_DIR}/pulse \
	--ro-bind ${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY} ${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY} \
	--dev-bind "${QQ_APP_DIR}" "${QQ_APP_DIR}" \
	--ro-bind /lib64/libvulkan.so.1 ${QQ_APP_DIR}/libvulkan.so.1 \
	--ro-bind ${QQ_APP_DIR}/index.js ${QQ_APP_DIR}/resources/app/app_launcher/index.js \
	--dev-bind ${QQ_APP_DIR}/package.json ${QQ_APP_DIR}/resources/app/package.json \
	--tmpfs /dev/shm  \
	--ro-bind-try "${XDG_CONFIG_HOME}/gtk-3.0" "${XDG_CONFIG_HOME}/gtk-3.0" \
	--setenv NO_AT_BRIDGE 1 \
	--setenv WEBKIT_DISABLE_COMPOSITING_MODE 1 \
	--setenv ELECTRON_OZONE_PLATFORM_HINT auto \
	--setenv APPDIR ${APPDIR} \
	${LiteLoader} ${HOTUPDATE}   \
	${APPDIR}/qq ${CMD#* } --ignore-gpu-blocklist ${Wayland}  --force-dark-mode --enable-features=WebUIDarkMode --enable-zero-copy ${APPDIR}/resources/app"
	#strace -y -o /tmp/logs/log
set_up_dbus_proxy &
bwrap `echo $Part`
pkill -TERM -P $$
