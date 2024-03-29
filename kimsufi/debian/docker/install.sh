#!/bin/bash

###########################################
# Declare variables
###########################################

IP_ADDRESS=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`

# Users
DOCKER_GROUP="dockerz"
DOCKER_USER="dockerz"
DOCKER_HOME="/home/${DOCKER_USER}"
RTORRENT_GROUP="rtorrent"
RTORRENT_USER="rtorrent"
RTORRENT_HOME="/home/${RTORRENT_USER}"

PATH=$PATH:/usr/sbin;export PATH

###########################################
# Install packages
###########################################

# Install packages
sudo apt-get --assume-yes install git sudo tmux bash-completion ca-certificates
sudo apt-get --assume-yes install inotify-tools unar curl lm-sensors
#sudo apt-get --assume-yes install certbot python-certbot-nginx

sudo update-alternatives --set editor /usr/bin/vim.basic

###########################################
# Add Docker Repo
###########################################

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

###########################################
# Install Docker packages
###########################################

# Install packages
sudo apt-get --assume-yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

###########################################
# Create Docker group
###########################################

# Create Docker group
sudo addgroup docker

###########################################
# Create Docker user
###########################################

# Create Docker user
sudo adduser -m --home ${DOCKER_HOME} --ingroup ${DOCKER_GROUP} --disabled-login --disabled-password --shell /bin/bash --gecos "Docker" ${DOCKER_USER}

# Create .docker directory
sudo mkdir ${DOCKER_HOME}"/.docker

###########################################
# Fix .docker permissions
###########################################

# Fix .docker permissions
sudo chown "${DOCKER_USER}":"${DOCKER_USER}" ${DOCKER_HOME}"/.docker -R
sudo chmod g+rwx "{$DOCKER_HOME}/.docker" -R

###########################################
# Enable Docker services
###########################################

sudo systemctl enable docker.service
sudo systemctl enable containerd.service

###########################################
# Create rtorrent directories
###########################################

# Create subdirectories
mkdir -p ${RTORRENT_HOME}/config
mkdir -p ${RTORRENT_HOME}/downloads
mkdir -p ${RTORRENT_HOME}/queue
mkdir -p ${RTORRENT_HOME}/session
mkdir -p ${RTORRENT_HOME}/watch

###########################################
# Configure rTorrent
###########################################

cat <<-RTORRENT_CONFIG > ${RTORRENT_HOME}/config/.rtorrent.rc
#This is an example resource file for rTorrent. Copy to
# ~/.rtorrent.rc and enable/modify the options as needed. Remember to
# uncomment the options you wish to enable.
# Maximum and minimum number of peers to connect to per torrent.
#min_peers = 40
#max_peers = 100
# Same as above but for seeding completed torrents (-1 = same as downloading)
#min_peers_seed = 10
#max_peers_seed = 50
# Maximum number of simultanious uploads per torrent.
max_uploads = 3
# Global upload and download rate in KiB. "0" for unlimited.
download_rate = 2000
upload_rate = 2000
# Default directory to save the downloaded torrents.
directory = ${RTORRENT_HOME}/downloads
# Default session directory. Make sure you don't run multiple instance
# of rtorrent using the same session directory. Perhaps using a
# relative path?
session = ${RTORRENT_HOME}/session
# Watch a directory for new torrents, and stop those that have been
# deleted.
schedule = watch_directory,5,5,load_start=${RTORRENT_HOME}/watch/*.torrent
#schedule = untied_directory,5,5,stop_untied=
# Close torrents when diskspace is low.
#schedule = low_diskspace,5,60,close_low_diskspace=100M
# The ip address reported to the tracker.
ip = ${IP_ADDRESS}
#ip = rakshasa.no
# The ip address the listening socket and outgoing connections is
# bound to.
bind = ${IP_ADDRESS}
#bind = rakshasa.no
# Port range to use for listening.
port_range = 60125-64125
# Start opening ports at a random position within the port range.
port_random = yes
# Check hash for finished torrents. Might be usefull until the bug is
# fixed that causes lack of diskspace not to be properly reported.
check_hash = yes
# Set whetever the client should try to connect to UDP trackers.
#use_udp_trackers = yes
# Alternative calls to bind and ip that should handle dynamic ip's.
#schedule = ip_tick,0,1800,ip=rakshasa
#schedule = bind_tick,0,1800,bind=rakshasa
# Encryption options, set to none (default) or any combination of the following:
# allow_incoming, try_outgoing, require, require_RC4, enable_retry, prefer_plaintext
#
# The example value allows incoming encrypted connections, starts unencrypted
# outgoing connections but retries with encryption if they fail, preferring
# plaintext to RC4 encryption after the encrypted handshake
#
encryption = allow_incoming,enable_retry,prefer_plaintext
# Enable DHT support for trackerless torrents or when all trackers are down.
# May be set to "disable" (completely disable DHT), "off" (do not start DHT),
# "auto" (start and stop DHT as needed), or "on" (start DHT immediately).
# The default is "off". For DHT to work, a session directory must be defined.
#
# dht = auto
# UDP port to use for DHT.
#
dht_port = 63425
# Enable peer exchange (for torrents not marked private)
#
peer_exchange = yes
#
# Do not modify the following parameters unless you know what you're doing.
#
# Hash read-ahead controls how many MB to request the kernel to read
# ahead. If the value is too low the disk may not be fully utilized,
# while if too high the kernel might not be able to keep the read
# pages in memory thus end up trashing.
#hash_read_ahead = 10
# Interval between attempts to check the hash, in milliseconds.
#hash_interval = 100
# Number of attempts to check the hash while using the mincore status,
# before forcing. Overworked systems might need lower values to get a
# decent hash checking rate.
#hash_max_tries = 10
ratio.enable =
ratio.min.set=300
system.method.set = group.seeding.ratio.command, d.close=, d.erase=
RTORRENT_CONFIG
