FROM ich777/novnc-baseimage

LABEL maintainer="admin@minenet.at"

RUN export TZ=Europe/Rome && \
	apt-get update && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
	apt-get -y install --no-install-recommends python3-pyqt5 libsecp256k1-0 python3-cryptography && \
	rm -rf /var/lib/apt/lists/* && \
	sed -i '/    document.title =/c\    document.title = "Electrum - noVNC";' /usr/share/novnc/app/ui.js && \
	rm /usr/share/novnc/app/images/icons/*


ENV DATA_DIR=/electrum
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV USER="electrum"

RUN mkdir $DATA_DIR && \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	mkdir /etc/.fluxbox && \
	ulimit -n 2048

ADD /scripts/ /opt/scripts/
# COPY /icons/* /usr/share/novnc/app/images/icons/
COPY /config/ /etc/.fluxbox
RUN chmod -R 770 /opt/scripts/ && \
	chown -R ${UID}:${GID} /etc/.fluxbox && \
	chmod -R 770 /etc/.fluxbo

EXPOSE 8080

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]