#!/usr/bin/zsh

USER_RUN_DIR="/run/user/$(id -u)"
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

QQ_HOTUPDATE_DIR="${QQ_APP_DIR}/versions"
QQ_HOTUPDATE_VERSION="${QQ_HOTUPDATE_DIR}/${QQ_HOTUPDATE_VERSION}"
HOTUPDATE="--ro-bind $APPDIR/resources/app ${QQ_HOTUPDATE_DIR}"

if [[ -z "${QQ_DOWNLOAD_DIR}" ]] {
	if [[ -z "${XDG_DOWNLOAD_DIR}" ]] {
		XDG_DOWNLOAD_DIR="$(xdg-user-dir DOWNLOAD)"
		}
	QQ_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
	}


# 环境问题
if [[ ! -d ${LOGIN} ]] {
mkdir -p  ${LOGIN}
chmod 700 ${LOGIN}
}


if [[ ! -d "${QQ_APP_DIR}" ]] {
# 从一大串arg提取key
keyname=AppImage


	if [[ ${${CMD##* }##*\.} == ${keyname} ]] {
	#别动 不然启动后缀出现两次
	unset CMD
	}
	#下面请随意
	if [[  ${QQdir##*\.} != ${keyname} ]] {
	echo "only name./AppImage"
	return -1
	}

	trap "rm -rf ${QQ_APP_DIR} ;return -1"INT
	cp $QQdir ${QQ_APP_ROOTDIR}
	cd ${QQ_APP_ROOTDIR}
	chmod +x ${QQ_APP_ROOTDIR}/${QQdir##*\/}
	./${QQdir##*\/} --appimage-extract > /dev/null
	rm ${QQ_APP_ROOTDIR}/${QQdir##*\/}

	rm -rf ${QQ_APP_DIR}/resources/app/fonts
	rm -rf ${QQ_APP_DIR}/{usr/lib,libEGL.so,libGLESv2.so,libvk_swiftshader.so,libvulkan.so.*}
	rm -f ${QQ_APP_DIR}/resources/app/{libssh2.so.1,libunwind*,sharp-lib/libvips-cpp.so.42}
	mkdir ${QQ_HOTUPDATE_DIR}
}

trap "exit -1" INT


function command_exists() {
	local command="$1"
	command -v "${command}" >/dev/null 2>&1
}

if [[ -d "${LOAD}" ]] {
	mkdir ${QQ_APP_DIR}/resources/app/LiteLoader
	Config="--dev-bind $LOAD/data/data ${QQ_APP_DIR}/resources/app/LiteLoader/data/data"
	if [[ -f $LOAD/data/data/LiteLoader/config.json  ]] {
		pushd $LOAD/data/data
		for dir in ./*
			do
			if [[ -d "$dir" ]] {
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
			}
			done
		popd
	}
	LiteLoader="--ro-bind $LOAD/package.json ${QQ_APP_DIR}/resources/app/LiteLoader/package.json \
	--ro-bind $LOAD/src ${QQ_APP_DIR}/resources/app/LiteLoader/src \
	--dev-bind $LOAD/data/plugins ${QQ_APP_DIR}/resources/app/LiteLoader/data/plugins \
	$Config \
	--dev-bind $LOAD/data/config.json ${QQ_APP_DIR}/resources/app/LiteLoader/data/config.json \
	--ro-bind /etc/ssl /etc/ssl \
	--setenv LITELOADERQQNT_PROFILE ${QQ_APP_DIR}/resources/app/LiteLoader/data"
	grep -q $LOAD ${QQ_APP_DIR}/resources/app/app_launcher/index.js|| sed -i "1 i require(\"${QQ_APP_DIR}/resources/app/LiteLoader/\");"  ${QQ_APP_DIR}/resources/app/app_launcher/index.js
}

Wayland="--enable-wayland-ime --setenv --ozone-platform-hint=wayland  --enable-features=WaylandWindowDecorations"


USER_RUN_DIR="/run/user/$(id -u)"
Part="--new-session --cap-drop ALL --unshare-user-try --unshare-pid --unshare-cgroup-try --die-with-parent \
	--symlink usr/lib /lib \
	--symlink usr/lib64 /lib64 \
	--ro-bind /usr /usr \
	--ro-bind /usr/bin/flatpak-xdg-open /bin/xdg-open \
	--ro-bind /usr/bin/kdialog /bin/kdialog  \
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
	--dev-bind ${LOGIN} ${HOME}/.config/QQ \
	--proc /proc \
	--dev-bind /run/dbus /run/dbus \
	--ro-bind-try /etc/fonts /etc/fonts \
	--dev-bind /tmp /tmp \
	--bind "${USER_RUN_DIR}" "${USER_RUN_DIR}" \
	--bind-try "${QQ_DOWNLOAD_DIR}" "${QQ_DOWNLOAD_DIR}" \
	--bind "${QQ_APP_DIR}" "${QQ_APP_DIR}" \
	--ro-bind-try "${FONTCONFIG_HOME}" "${FONTCONFIG_HOME}" \
	--tmpfs /dev/shm  \
	--ro-bind-try "${XDG_CONFIG_HOME}/gtk-3.0" "${XDG_CONFIG_HOME}/gtk-3.0" \
	--setenv APPDIR ${APPDIR} \
	--setenv  PATH  /bin \
	${LiteLoader} ${HOTUPDATE}   \
	${APPDIR}/qq ${CMD#* } --ignore-gpu-blocklist ${Wayland}  --force-dark-mode --enable-features=WebUIDarkMode --enable-zero-copy"
	#strace -y -o /tmp/logs/log
bwrap `echo $Part`
rm -rf /tmp/QQ
