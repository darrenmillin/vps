#!/bin/bash

###########################################
# Declare variables
###########################################

IP_ADDRESS=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`

# Users
DOCKER_USER="docker"
DOCKER_HOME="/home/${DOCKER_USER}"
RTORRENT_USER="rtorrent"
RTORRENT_HOME="/home/${RTORRENT_USER}"

###########################################
# Install packages
###########################################

# Install packages
apt-get --assume-yes install git sudo tmux bash-completion ca-certificates
apt-get --assume-yes install inotify-tools unar rtorrent curl nginx lm-sensors
apt-get --assume-yes install certbot python-certbot-nginx

update-alternatives --set editor /usr/bin/vim.basic

###########################################
# Create Docker group
###########################################

# Create Docker group
groupadd docker

###########################################
# Create Docker user
###########################################

# Create Docker user
adduser --home ${DOCKER_HOME} --disabled-password --shell /bin/bash --gecos "Docker User" ${DOCKER_USER}

# Create .docker directory
mkdir ${DOCKER_HOME}"/.docker

###########################################
# Create .docker user
###########################################

# Fix .docker permissions
chown "${DOCKER_USER}":"${DOCKER_USER}" ${DOCKER_HOME}"/.docker -R
chmod g+rwx "$DOCKER_HOME/.docker" -R

###########################################
# Enable Docker services
###########################################

$ systemctl enable docker.service
$ systemctl enable containerd.service

###########################################
# Create rTorrent directories
###########################################

# Create subdirectories
mkdir -p ${RTORRENT_HOME}/downloads
mkdir -p ${RTORRENT_HOME}/queue
mkdir -p ${RTORRENT_HOME}/session
mkdir -p ${RTORRENT_HOME}/watch

###########################################
# Configure rTorrent
###########################################

cat <<-RTORRENT_CONFIG > ${RTORRENT_HOME}/.rtorrent.rc
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

chown -R rtorrent:rtorrent ${RTORRENT_HOME}

###########################################
# Configure rTorrent Service
###########################################

cat <<-RTORRENT_SERVICE > /lib/systemd/system/rtorrent.service
[Unit]
Description=rTorrent
After=network.target
[Service]
Type=forking
ExecStart=/usr/bin/tmux new-session -c /home/rtorrent -s rtorrent -n rtorrent -d rtorrent
#ExecStop=/usr/bin/killall -w -s 2 /usr/bin/rtorrent
User=rtorrent
Group=rtorrent
[Install]
WantedBy=multi-user.target
Alias=rtorrent.service
RTORRENT_SERVICE

###########################################
# Enable rTorrent Service
###########################################

systemctl enable rtorrent
  
###########################################
# Install Resilio
###########################################

# Add the repo
echo "deb https://linux-packages.resilio.com/resilio-sync/deb resilio-sync non-free" | sudo tee /etc/apt/sources.list.d/resilio-sync.list

# Get key.asc
curl -LO https://linux-packages.resilio.com/resilio-sync/key.asc && sudo apt-key add ./key.asc

# Remove key.asc
rm ./key.asc

# Install the resilio package
apt-get update
apt-get install resilio-sync

###########################################
# Update the resilio config
###########################################

cat <<-RESILIO_CONFIG > /etc/resilio-sync/config.json
{
    "storage_path" : "/var/lib/resilio-sync/",
    "pid_file" : "/var/run/resilio-sync/sync.pid",

    "webui" :
    {
        "listen" : "0.0.0.0:8888"
    }
}
RESILIO_CONFIG

###########################################
# Start resilio config
###########################################

# Enable the resilio-sync service
systemctl enable resilio-sync
systemctl start resilio-sync

###########################################
# Update the nginx config
###########################################

# Stop Nginx
systemctl stop nginx

cat <<-NGINX_CONFIG > /etc/nginx/sites-available/default
##
# You should look at the following URL's in order to grasp a solid understanding
# of Nginx configuration files in order to fully unleash the power of Nginx.
# https://www.nginx.com/resources/wiki/start/
# https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/
# https://wiki.debian.org/Nginx/DirectoryStructure
#
# In most cases, administrators will remove this file from sites-enabled/ and
# leave it as reference inside of sites-available where it will continue to be
# updated by the nginx packaging team.
#
# This file will automatically load configuration files provided by other
# applications, such as Drupal or Wordpress. These applications will be made
# available underneath a path with that package name, such as /drupal8.
#
# Please see /usr/share/doc/nginx-doc/examples/ for more detailed examples.
##
# Default server configuration
#
server {
        listen 80 default_server;
        listen [::]:80 default_server;
        # SSL configuration
        #
        # listen 443 ssl default_server;
        # listen [::]:443 ssl default_server;
        #
        # Note: You should disable gzip for SSL traffic.
        # See: https://bugs.debian.org/773332
        #
        # Read up on ssl_ciphers to ensure a secure configuration.
        # See: https://bugs.debian.org/765782
        #
        # Self signed certs generated by the ssl-cert package
        # Don't use them in a production server!
        #
        # include snippets/snakeoil.conf;
        root /var/www/html;
        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;
        server_name _;
        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }
        
        access_log /var/log/nginx/resilio_access.log;
        error_log /var/log/nginx/resilio_error.log;
        
        location /gui/ {
                proxy_pass http://${IP_ADDRESS}:8888/gui/;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
        
        # pass PHP scripts to FastCGI server
        #
        #location ~ \.php$ {
        #       include snippets/fastcgi-php.conf;
        #
        #       # With php-fpm (or other unix sockets):
        #       fastcgi_pass unix:/run/php/php7.3-fpm.sock;
        #       # With php-cgi (or other tcp sockets):
        #       fastcgi_pass 127.0.0.1:9000;
        #}
        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #       deny all;
        #}
}
# Virtual Host configuration for example.com
#
# You can move that to a different file under sites-available/ and symlink that
# to sites-enabled/ to enable it.
#
#server {
#       listen 80;
#       listen [::]:80;
#
#       server_name example.com;
#
#       root /var/www/example.com;
#       index index.html;
#
#       location / {
#               try_files $uri $uri/ =404;
#       }
#}
NGINX_CONFIG

# Start Nginx
systemctl start nginx

###########################################
# Restart resilio
###########################################

systemctl restart resilio-sync
