#!/bin/bash
export DISPLAY=:99
export XDG_RUNTIME_DIR=/tmp/runtime-electrum

CUR_V="$(python3 ${DATA_DIR}/run_electrum -o version 2>/dev/null)"
LAT_V="$(wget -qO- https://github.com/ich777/versions/raw/master/Electrum | grep LATEST | cut -d '=' -f2)"

if [ -z "$LAT_V" ]; then
	if [ ! -z "$CUR_V" ]; then
		echo "---Can't get latest version of Electrum falling back to v$CUR_V---"
		LAT_V="$CUR_V"
	else
		echo "---Something went wrong, can't get latest version of Electrum, putting container into sleep mode---"
		sleep infinity
	fi
fi

echo "---Version Check---"
if [ -z "$CUR_V" ]; then
	echo "---Electrum not installed, installing---"
    cd ${DATA_DIR}
	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/Electrum-$LAT_V.tar.gz https://download.electrum.org/$LAT_V/Electrum-$LAT_V.tar.gz ; then
    	echo "---Sucessfully downloaded Electrum---"
    else
    	echo "---Something went wrong, can't download Electrum, putting container in sleep mode---"
        sleep infinity
    fi
	tar -C ${DATA_DIR} --strip-components=1 -xf ${DATA_DIR}/Electrum-$LAT_V.tar.gz
	rm -R ${DATA_DIR}/Electrum-$LAT_V.tar.gz
elif [ "$CUR_V" != "$LAT_V" ]; then
	echo "---Version missmatch, installed v$CUR_V, downloading and installing latest v$LAT_V...---"
    cd ${DATA_DIR}
	rm -R ${DATA_DIR}/*
	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/Electrum-$LAT_V.tar.gz https://download.electrum.org/$LAT_V/Electrum-$LAT_V.tar.gz ; then
    	echo "---Sucessfully downloaded Electrum---"
    else
    	echo "---Something went wrong, can't download Electrum, putting container in sleep mode---"
        sleep infinity
    fi
	tar -C ${DATA_DIR} --strip-components=1 -xf ${DATA_DIR}/Electrum-$LAT_V.tar.gz
	rm -R ${DATA_DIR}/Electrum-$LAT_V.tar.gz
elif [ "$CUR_V" == "$LAT_V" ]; then
	echo "---Electrum v$CUR_V up-to-date---"
fi

echo "---Preparing Server---"
if [ ! -d ${DATA_DIR}/.electrum/wallets ]; then
	mkdir -p ${DATA_DIR}/.electrum/wallets
fi
if [ ! -d /tmp/runtime-electrum ]; then
	mkdir -p /tmp/runtime-electrum
	chmod -R 0700 /tmp/runtime-electrum
fi
echo "---Resolution check---"
if [ -z "${CUSTOM_RES_W} ]; then
	CUSTOM_RES_W=1024
fi
if [ -z "${CUSTOM_RES_H} ]; then
	CUSTOM_RES_H=768
fi

if [ "${CUSTOM_RES_W}" -le 1024 ]; then
	echo "---Width to low must be a minimal of 1024 pixels, correcting to 1024...---"
    CUSTOM_RES_W=1024
fi
if [ "${CUSTOM_RES_H}" -le 768 ]; then
	echo "---Height to low must be a minimal of 768 pixels, correcting to 768...---"
    CUSTOM_RES_H=768
fi
echo "---Checking for old logfiles---"
find $DATA_DIR -name "XvfbLog.*" -exec rm -f {} \;
find $DATA_DIR -name "x11vncLog.*" -exec rm -f {} \;
echo "---Checking for old display lock files---"
find /tmp -name ".X99*" -exec rm -f {} \; > /dev/null 2>&1
screen -wipe 2&>/dev/null

chmod -R ${DATA_PERM} ${DATA_DIR}

echo "---Starting Xvfb server---"
screen -S Xvfb -L -Logfile ${DATA_DIR}/XvfbLog.0 -d -m /opt/scripts/start-Xvfb.sh
sleep 2
echo "---Starting x11vnc server---"
screen -S x11vnc -L -Logfile ${DATA_DIR}/x11vncLog.0 -d -m /opt/scripts/start-x11.sh
sleep 2
echo "---Starting Fluxbox---"
screen -d -m env HOME=/etc /usr/bin/fluxbox
sleep 2
echo "---Starting noVNC server---"
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem 8080 localhost:5900
sleep 2

echo "---Starting Electrum---"
cd ${DATA_DIR}
/usr/bin/python3 ${DATA_DIR}/run_electrum