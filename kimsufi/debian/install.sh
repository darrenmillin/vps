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
RTORRENT_HOME="/home/${RTORRENT_USER}"
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

##############################################
# Create Docker scripts
##############################################

cat <<-COMPOSE >> ${DOCKER_HOME}/scripts/compose.yaml
name: rtorrent-rutorrent
version: "3"
services:
  rtorrent-rutorrent:
    image: darrenmillin/rtorrent-rutorrent:latest 
    container_name: rtorrent-rutorrent
    volumes:
      - /data/rtorrent:/data
      - /data/rtorrent/downloads:/downloads
      - /data/rtorrent/passwd:/passwd
    environment:
      - PUID=1002
      - PGID=1002
    ports:
      - 6881:6881/udp
      - 5000:5000
      - 8000:8000
      - 8080:8080
      - 9000:9000
    restart: always
COMPOSE

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

