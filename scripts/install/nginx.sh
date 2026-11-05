#!/bin/bash
# nginx installer
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

distribution=$(_os_distro)
codename=$(_os_codename)

if [[ -n $(pidof apache2) ]] || [[ -n $(pidof httpd) ]]; then
    if [[ -z $apache2 ]]; then
        if (whiptail --title "apache2 conflict" --yesno --yes-button "Purge it!" --no-button "Disable it" "WARNING: The installer has detected that apache is already installed. To continue, the installer must either purge apache or disable it." 8 78); then
            apache2=purge
        else
            apache2=disable
        fi
    fi
    if [[ $apache2 == "purge" ]]; then
        echo_progress_start "Purging apache"
        systemctl disable --now httpd >> /dev/null 2>&1 || true
        pac_remove --purge apache
        echo_progress_done "Apache purged"
    elif [[ $apache2 == "disable" ]]; then
        echo_progress_start "Disabling apache"
        systemctl disable --now httpd >> /dev/null 2>&1 || true
        echo_progress_done "Apache disabled"
    fi
fi

# Ensure http user and group exist
groupadd -f http
id -u http > /dev/null 2>&1 || useradd -r -g http -d /srv/http -s /usr/bin/nologin http

# Prepare the /etc/nginx/ssl/ for openssl dhparm generation
mkdir -p /etc/nginx/ssl/
chmod 700 /etc/nginx/ssl
cd /etc/nginx/ssl

# Create temp.log for openssl dhparm generation to prevent a race condition with logging
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
templog="/root/logs/temp.log"
rm_if_exists $templog
touch $templog

# Start openssl dhparam as a background task using temp.log
openssl dhparam -out dhparam.pem 2048 >> $templog 2>&1 &

# Install packages for nginx in the foreground
pac_install nginx php php-fpm php-gd php-intl php-sqlite fcgi openssl geoip-database subversion
aur_install --ignore-errors nginx-mod-fancyindex

# Wait for the background task of openssl dhparm generation to finish
wait

# Append the results of temp.log to swizzin.log and remove temp.log
echo_log_only "Begin of OpenSSL dhparm results"
cat $templog >> $log 2>&1
echo_log_only "End of OpenSSL dhparm results"
rm_if_exists $templog

# Generate snakeoil SSL certificate and key if missing
mkdir -p /etc/ssl/certs /etc/ssl/private
if [[ ! -f /etc/ssl/certs/ssl-cert-snakeoil.pem ]] || [[ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ]]; then
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
        -out /etc/ssl/certs/ssl-cert-snakeoil.pem \
        -subj "/CN=localhost" >> $log 2>&1
    chmod 600 /etc/ssl/private/ssl-cert-snakeoil.key
fi

# Began configuring nginx and PHP in the foreground
mkdir -p /srv
echo_progress_start "Making adjustments to PHP"
if [[ -f /etc/php/php.ini ]]; then
    sed -i -e "s/post_max_size = 8M/post_max_size = 64M/" \
        -e "s/upload_max_filesize = 2M/upload_max_filesize = 92M/" \
        -e "s/expose_php = On/expose_php = Off/" \
        -e "s/128M/768M/" \
        -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" \
        -e "s/;opcache.enable=0/opcache.enable=1/" \
        -e "s/;opcache.enable=1/opcache.enable=1/" \
        -e "s/;opcache.memory_consumption=64/opcache.memory_consumption=128/" \
        -e "s/;opcache.memory_consumption=128/opcache.memory_consumption=128/" \
        -e "s/;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/" \
        -e "s/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=4000/" \
        -e "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=240/" \
        -e "s/^;extension=bcmath/extension=bcmath/" \
        -e "s/^;extension=curl/extension=curl/" \
        -e "s/^;extension=gd/extension=gd/" \
        -e "s/^;extension=gettext/extension=gettext/" \
        -e "s/^;extension=iconv/extension=iconv/" \
        -e "s/^;extension=intl/extension=intl/" \
        -e "s/^;extension=mysqli/extension=mysqli/" \
        -e "s/^;extension=pdo_mysql/extension=pdo_mysql/" \
        -e "s/^;extension=pdo_sqlite/extension=pdo_sqlite/" \
        -e "s/^;extension=sockets/extension=sockets/" \
        -e "s/^;extension=sqlite3/extension=sqlite3/" \
        -e "s/^;extension=zip/extension=zip/" \
        -e "s/^;zend_extension=opcache/zend_extension=opcache/" \
        /etc/php/php.ini
fi

mkdir -p /etc/php/php-fpm.d /run/php-fpm
if [[ -f /etc/php/php-fpm.d/www.conf ]]; then
    sed -i -e "s|^user = .*|user = http|" \
        -e "s|^group = .*|group = http|" \
        -e "s|^listen = .*|listen = /run/php-fpm/php-fpm.sock|" \
        -e "s|^;listen.owner = .*|listen.owner = http|" \
        -e "s|^listen.owner = .*|listen.owner = http|" \
        -e "s|^;listen.group = .*|listen.group = http|" \
        -e "s|^listen.group = .*|listen.group = http|" \
        -e "s|^;listen.mode = .*|listen.mode = 0660|" \
        -e "s|^listen.mode = .*|listen.mode = 0660|" \
        -e "s|;env\[PATH\]|env[PATH]|g" \
        /etc/php/php-fpm.d/www.conf
fi
ln -sfn /run/php-fpm /run/php
mkdir -p /etc/tmpfiles.d
echo "L+ /run/php - - - - /run/php-fpm" > /etc/tmpfiles.d/swizzin-php.conf
systemctl enable --now php-fpm.service >> $log 2>&1
echo_progress_done "PHP config modified"

mkdir -p /etc/nginx/modules-enabled/ /etc/nginx/conf.d/ /etc/nginx/sites-enabled/ /etc/nginx/snippets/ /etc/nginx/apps/
if [[ -f /usr/lib/nginx/modules/ngx_http_fancyindex_module.so ]]; then
    echo 'load_module "/usr/lib/nginx/modules/ngx_http_fancyindex_module.so";' > /etc/nginx/modules-enabled/50-mod-http-fancyindex.conf
fi

#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php
sock="php-fpm"
echo_info "Using /run/php-fpm/${sock}.sock in the nginx config"

cat > /etc/nginx/nginx.conf << 'NGCONF'
user http;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
NGCONF

cat > /etc/nginx/snippets/fastcgi-php.conf << 'FCGIPHP'
fastcgi_split_path_info ^(.+\.php)(/.+)$;
try_files $fastcgi_script_name =404;
set $path_info $fastcgi_path_info;
fastcgi_param PATH_INFO $path_info;
fastcgi_index index.php;
include fastcgi.conf;
FCGIPHP

rm -rf /etc/nginx/sites-enabled/default

echo_progress_start "Creating default nginx site config and certificates"
cat > /etc/nginx/sites-enabled/default << NGC
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;
  server_tokens off;

  location /.well-known {
    alias /srv/.well-known;
    allow all;
    default_type "text/plain";
    autoindex    on;
  }

  location / {
    return 301 https://\$host\$request_uri;
  }
}

# SSL configuration
server {
  listen 443 ssl http2 default_server;
  listen [::]:443 ssl http2 default_server;
  server_name _;
  ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
  ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
  include snippets/ssl-params.conf;
  client_max_body_size 40M;
  server_tokens off;
  root /srv/;

  # PHP-FPM socket: unix:/run/php-fpm/php-fpm.sock
  include /etc/nginx/apps/*.conf;

  location ~ /\.ht {
    deny all;
  }
}
NGC

mkdir -p /etc/nginx/snippets/
mkdir -p /etc/nginx/apps/

cat > /etc/nginx/snippets/ssl-params.conf << SSC
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:EECDH+AESGCM:EDH+AESGCM;
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 127.0.0.1 valid=300s;
resolver_timeout 5s;
# Disable preloading HSTS for now.  You can use the commented out header line that includes
# the "preload" directive if you understand the implications.
#add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
#add_header X-Frame-Options DENY;
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;

ssl_dhparam /etc/nginx/ssl/dhparam.pem;
SSC

cat > /etc/nginx/snippets/proxy.conf << PROX
client_max_body_size 40m;
client_body_buffer_size 128k;

#Timeout if the real server is dead
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;

# Advanced Proxy Config
send_timeout 5m;
proxy_read_timeout 240;
proxy_send_timeout 240;
proxy_connect_timeout 240;

# Basic Proxy Config
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto https;
#proxy_redirect  http://  \$scheme://;
proxy_http_version 1.1;
proxy_set_header Connection "";
proxy_cache_bypass \$cookie_session;
proxy_no_cache \$cookie_session;
proxy_buffers 32 4k;
PROX
echo_progress_done "Config installed"

echo_progress_start "Installing fancyindex"
git clone https://github.com/Naereen/Nginx-Fancyindex-Theme/ /tmp/fancyindex >> $log 2>&1
mv /tmp/fancyindex/Nginx-Fancyindex-Theme-dark /srv/fancyindex >> $log 2>&1
rm -rf /tmp/fancyindex

cat > /etc/nginx/snippets/fancyindex.conf << FIC
fancyindex on;
fancyindex_localtime on;
fancyindex_exact_size off;
fancyindex_header "/fancyindex/header.html";
fancyindex_footer "/fancyindex/footer.html";
#fancyindex_ignore "examplefile.html"; # Ignored files will not show up in the directory listing, but will still be public.
#fancyindex_ignore "Nginx-Fancyindex-Theme"; # Making sure folder where files are don't show up in the listing.
fancyindex_name_length 255; # Maximum file name length in bytes, change as you like.
FIC
sed -i 's/href="\/[^\/]*/href="\/fancyindex/g' /srv/fancyindex/header.html
sed -i 's/src="\/[^\/]*/src="\/fancyindex/g' /srv/fancyindex/footer.html

#Some ruTorrent plugins need to bypass htpasswd, so we stuff the php for this here
cat > /etc/nginx/apps/fancyindex.conf << FIAC
location /fancyindex {
    location ~ \.php($|/) {
        fastcgi_split_path_info ^(.+?\.php)(/.+)$;
        # Work around annoying nginx "feature" (https://trac.nginx.org/nginx/ticket/321)
        set \$path_info \$fastcgi_path_info;
        fastcgi_param PATH_INFO \$path_info;

        # Make sure the script exists.
        try_files \$fastcgi_script_name =404;
        fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$request_filename;
        include fastcgi_params;
        fastcgi_index index.php;
    }
}
FIAC
echo_progress_done "Fancyindex installed"

locks=($(find /usr/local/bin/swizzin/nginx -type f -printf "%f\n" | cut -d "." -f 1 | sort -d -r))
for i in "${locks[@]}"; do
    app=${i}
    if [[ -f /install/.$app.lock ]]; then
        echo_progress_start "Installing nginx config for $app"
        bash /usr/local/bin/swizzin/nginx/$app.sh
        echo_progress_done "Nginx config for $app installed"
    fi
done

echo_progress_start "Restarting nginx"
systemctl enable --now nginx >> $log 2>&1
systemctl restart nginx
echo_progress_done "Nginx restarted"

#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php
restart_php_fpm

echo_success "Nginx installed"
touch /install/.nginx.lock
