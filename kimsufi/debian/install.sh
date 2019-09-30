#!/bin/bash

# Install packages
apt-get --assume-yes install git sudo tmux bash-completion ca-certificates
apt-get --assume-yes install rtorrent curl nginx lm-sensors
  
update-alternatives --set editor /usr/bin/vim.basic
  
# Create rtorrent user
RTORRENT_HOME="/home/rtorrent"
adduser --home ${RTORRENT_HOME} --disabled-password --shell /bin/bash --gecos "rTorrent User" rtorrent

# Create subdirectories
mkdir -p ${RTORRENT_HOME}/downloads
mkdir -p ${RTORRENT_HOME}/queue
mkdir -p ${RTORRENT_HOME}/session
mkdir -p ${RTORRENT_HOME}/watch

# Change ownership of ~rtorrent
chown -R rtorrent:rtorrent ${RTORRENT_HOME}
