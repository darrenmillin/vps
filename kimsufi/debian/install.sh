#!/bin/bash

##############################################
# Declare variables
##############################################

IP_ADDRESS=`hostname -I | awk '{ print $1}'`

# Users
CERTBOT_USER="certbot"
CERTBOT_HOME="/data/${CERTBOT_USER}"
DOCKER_USER="docker"
DOCKER_HOME="/home/${DOCKER_USER}"
NGINX_USER="nginx"
NGINX_HOME="/data/${NGINX_USER}"
RESILIO_SYNC_USER="sync"
RESILIO_SYNC_HOME="/data/${RESILIO_SYNC_USER}"
RTORRENT_USER="rtorrent"
RTORRENT_HOME="/data/${RTORRENT_USER}"
RTORRENT_DATA_HOME="/data/${RTORRENT_USER}"

##############################################
# Install packages
##############################################

# Install packages
sudo apt-get --assume-yes update
sudo apt-get --assume-yes install git sudo tmux bash-completion
sudo apt-get --assume-yes install inotify-tools unar lm-sensors
sudo apt-get --assume-yes install dbus-user-session fuse-overlayfs
sudo apt-get --assume-yes install uidmap
sudo apt-get --assume-yes update

sudo update-alternatives --set editor /usr/bin/vim.basic

##############################################
# Add Docker Repo
##############################################

# Add Docker's official GPG key:
sudo apt-get --assume-yes update
sudo apt-get --assume-yes install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get --assume-yes update

##############################################
# Create Docker user
##############################################

# Create Docker user
sudo adduser --home ${DOCKER_HOME} --disabled-login --disabled-password --shell /bin/bash --gecos "Docker" ${DOCKER_USER}

# Create .docker directory
sudo mkdir ${DOCKER_HOME}/.docker

# Create scripts directory
sudo mkdir ${DOCKER_HOME}/scripts
sudo mkdir ${RTORRENT_HOME}/scripts

##############################################
# Create Docker scripts
##############################################

cat <<-ENV >> ${RTORRENT_HOME}/compose/.env
RT_DHT_PORT=6881
XMLRPC_PORT=8000
RUTORRENT_PORT=8080
WEBDAV_PORT=9000
RT_INC_PORT=50000
ENV

cat <<-COMPOSE >> ${RTORRENT_HOME}/compose/compose.yaml
name: rtorrent-rutorrent

services:
  geoip-updater:
    image: crazymax/geoip-updater:latest
    container_name: geoip-updater
    networks:
      - rtorrent-rutorrent
    volumes:
      - "./data/geoip:/data"
    env_file:
      - "./geoip-updater.env"
    restart: always

  rtorrent-rutorrent:
    image: darrenmillin/rtorrent-rutorrent:latest
    container_name: rtorrent-rutorrent
    networks:
      - rtorrent-rutorrent
    expose:
      - "${RT_DHT_PORT}/udp"
      - "${XMLRPC_PORT}"
      - "${RUTORRENT_PORT}"
      - "${WEBDAV_PORT}"
      - "${RT_INC_PORT}"
    ports:
      - target: ${RT_DHT_PORT}
        published: ${RT_DHT_PORT}
        protocol: udp
      - target: ${RUTORRENT_PORT}
        published: ${RUTORRENT_PORT}
        protocol: tcp
      - target: ${WEBDAV_PORT}
        published: ${WEBDAV_PORT}
        protocol: tcp
      - target: ${RT_INC_PORT}
        published: ${RT_INC_PORT}
        protocol: tcp
    env_file:
      - "rtorrent-rutorrent.env"
      - ".env"
    volumes:
      - "./data:/data"
      - "./downloads:/downloads"
      - "./passwd:/passwd"
 #   ulimits:
 #     nproc: 65535
 #     nofile:
 #       soft: 32000
 #       hard: 40000
    restart: always

  rtorrent-logs:
    image: bash
    container_name: rtorrent-rutorrent-logs
    command: bash -c 'tail -f /log/*.log'
    network_mode: none
    depends_on:
      - rtorrent-rutorrent
    volumes:
      - "./data/rtorrent/log:/log"
    restart: always

networks:
  rtorrent-rutorrent:
    name: rtorrent-rutorrent
COMPOSE

cat <<-GEOIP_UPDATER_ENV >> ${RTORRENT_HOME}/compose/geoip-updater.env
TZ=Europe/Paris
EDITION_IDS=GeoLite2-City,GeoLite2-Country
LICENSE_KEY=
DOWNLOAD_PATH=/data
SCHEDULE=0 0 * * 0
LOG_LEVEL=info
LOG_JSON=false
GEOIP_UPDATER_ENV

cat <<-RTORRENT_RUTORRENT_ENV >> ${RTORRENT_HOME}/compose/rtorrent-rutorrent.env
TZ=Europe/Paris
PUID=1000
PGID=1000

WAN_IP_CMD=false

AUTH_DELAY=0s
MEMORY_LIMIT=256M
UPLOAD_MAX_SIZE=16M
OPCACHE_MEM_SIZE=128
MAX_FILE_UPLOADS=50
REAL_IP_FROM=0.0.0.0/32
REAL_IP_HEADER=X-Forwarded-For
LOG_IP_VAR=remote_addr
LOG_ACCESS=true

XMLRPC_AUTHBASIC_STRING=rTorrent XMLRPC restricted access
RUTORRENT_AUTHBASIC_STRING=ruTorrent restricted access
WEBDAV_AUTHBASIC_STRING=WebDAV restricted access

RT_LOG_LEVEL=info
RT_LOG_EXECUTE=false
RT_LOG_XMLRPC=false

RU_REMOVE_CORE_PLUGINS=httprpc
RU_HTTP_USER_AGENT=Mozilla/5.0 (Windows NT 6.0; WOW64; rv:12.0) Gecko/20100101 Firefox/12.0
RU_HTTP_TIME_OUT=30
RU_HTTP_USE_GZIP=true
RU_RPC_TIME_OUT=5
RU_LOG_RPC_CALLS=false
RU_LOG_RPC_FAULTS=true
RU_PHP_USE_GZIP=false
RU_PHP_GZIP_LEVEL=2
RU_SCHEDULE_RAND=10
RU_LOG_FILE=/data/rutorrent/rutorrent.log
RU_DO_DIAGNOSTIC=true
RU_SAVE_UPLOADED_TORRENTS=true
RU_OVERWRITE_UPLOADED_TORRENTS=false
RU_FORBID_USER_SETTINGS=false
RU_LOCALE=UTF8
RTORRENT_RUTORRENT_ENV

cat <<-SCRIPT >> ${DOCKER_HOME}/scripts/start_rtorrent_rutorrent.sh
docker run -d --name rtorrent_rutorrent \
  -p 6881:6881/udp \
  -p 8000:8000 \
  -p 8080:8080 \
  -p 9000:9000 \
  -p 50000:50000 \
  -v /data/rtorrent:/data \
  -v /data/rtorrent/downloads:/downloads \
  -v /data/rtorrent/passwd:/passwd \
  darrenmillin/rtorrent-rutorrent:latest
SCRIPT

# Set ownership and permissions
sudo chown ${DOCKER_USER}:${DOCKER_USER} ${DOCKER_HOME}/scripts -R
sudo chmod 755 ${DOCKER_HOME}/scripts/start_rtorrent_rutorrent.sh

##############################################
# Create rTorrent user
##############################################

# Create rTorrent user
sudo adduser --home ${RTORRENT_HOME} --disabled-password --shell /bin/bash --gecos "rTorrent" ${RTORRENT_USER}

##############################################
# Create rTorrent data directories
##############################################

# Create rTorrent data directories
sudo mkdir -p ${RTORRENT_DATA_HOME}/data
sudo mkdir -p ${RTORRENT_DATA_HOME}/downloads
sudo mkdir -p ${RTORRENT_DATA_HOME}/passwd

# Change ownership
sudo chmod 755 ${RTORRENT_DATA_HOME}
sudo chown $(id -u ${RTORRENT_USER}):$(id -u ${RTORRENT_USER}) ${RTORRENT_DATA_HOME} -R

##############################################
# Fix .docker permissions
##############################################

# Fix .docker permissions
sudo chown ${DOCKER_USER}:${DOCKER_USER} ${DOCKER_HOME}/.docker -R
sudo chmod g+rwx ${DOCKER_HOME}/.docker -R

##############################################
# Install Docker
##############################################

sudo apt-get --assume-yes update
sudo apt-get --assume-yes install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo apt-get --assume-yes update

##############################################
# Create certbot directories
##############################################

# Create subdirectories
mkdir -p ${CERTBOT_HOME}/conf
mkdir -p ${CERTBOT_HOME}/www

# Change ownership
sudo chown ${DOCKER_USER}:${DOCKER_USER} ${CERTBOT_HOME} -R

##############################################
# Create nginx directories
##############################################

# Create subdirectories
mkdir -p ${NGINX_HOME}/conf.d

# Change ownership
sudo chown ${DOCKER_USER}:${DOCKER_USER} ${NGINX_HOME} -R

##############################################
# Create resilio sync directories
##############################################

# Create subdirectories
mkdir -p ${RESILIO_SYNC_HOME}/config
mkdir -p ${RESILIO_SYNC_HOME}/downloads
mkdir -p ${RESILIO_SYNC_HOME}/sync

# Change ownership
sudo chown ${DOCKER_USER}:${DOCKER_USER} ${RESILIO_SYNC_HOME} -R

##############################################
# Disable Rootful Docker
##############################################

sudo systemctl disable --now docker.service docker.socket

##############################################
# Install Rootless Docker
##############################################

sudo -iu ${DOCKER_USER} dockerd-rootless-setuptool.sh install --force

##############################################
# Update Docker .bashrc
##############################################

cat <<-BASHRC >> ${DOCKER_HOME}/.bashrc
export XDG_RUNTIME_DIR=${DOCKER_HOME}/.docker/run
export PATH=$PATH:/usr/libexec/docker/cli-plugins
export DOCKER_HOST=unix:///run/user/$(id -u ${DOCKER_USER})/docker.sock
BASHRC

##############################################
# Enable Rootless Docker to launch on startup.
##############################################

systemctl --user enable ${DOCKER_USER}
sudo loginctl enable-linger ${DOCKER_USER}

##############################################
# Expose privileged ports
##############################################

sudo setcap cap_net_bind_service=ep $(which rootlesskit)
systemctl --user restart docker

