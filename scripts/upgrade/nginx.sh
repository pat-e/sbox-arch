#!/bin/bash
# A script to reset your nginx configs to the latest versions "upgrading" nginx
# Beware, this script *will* overwrite any personal modifications you have made.
# Author: liara

hostname=$(grep -m1 "server_name" /etc/nginx/sites-enabled/default | awk '{print $2}' | sed 's/;//g')
locks=($(find /usr/local/bin/swizzin/nginx -type f -printf "%f\n" | cut -d "." -f 1 | sort -d -r))

if [[ ! -f /install/.nginx.lock ]]; then
    echo_error "nginx doesn't appear to be installed. What do you hope to accomplish by running this script?"
    exit 1
fi

for i in "${locks[@]}"; do
    app=${i}
    if [[ -f /install/.$app.lock ]]; then
        rm -f /etc/nginx/apps/$app.conf
    fi
done

rm -f /etc/nginx/apps/dindex.conf
rm -f /etc/nginx/apps/rindex.conf
rm -f /etc/nginx/apps/*.scgi.conf

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/conf.d/*
rm -f /etc/nginx/snippets/{ssl-params,proxy,fancyindex}.conf

#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php

pac_install nginx php php-fpm php-gd php-intl php-sqlite fcgi

if [[ ! -f /etc/nginx/modules-enabled/50-mod-http-fancyindex.conf ]] && [[ -f /usr/share/nginx/modules-available/mod-http-fancyindex.conf ]]; then
    mkdir -p /etc/nginx/modules-enabled/
    ln -s /usr/share/nginx/modules-available/mod-http-fancyindex.conf /etc/nginx/modules-enabled/50-mod-http-fancyindex.conf
fi

for i in NGC SSC PROX FIC FIAC; do
    cmd=$(sed -n -e '/'$i'/,/'$i'/ p' /etc/swizzin/scripts/install/nginx.sh)
    eval "$cmd"
done

if [[ ! $hostname == "_" ]]; then
    sed -i "s/server_name _;/server_name $hostname;/g" /etc/nginx/sites-enabled/default
    sed -i "s/ssl_certificate .*/ssl_certificate \/etc\/nginx\/ssl\/${hostname}\/fullchain.pem;/g" /etc/nginx/sites-enabled/default
    sed -i "s/ssl_certificate_key .*/ssl_certificate_key \/etc\/nginx\/ssl\/${hostname}\/key.pem;/g" /etc/nginx/sites-enabled/default
fi

for i in "${locks[@]}"; do
    app=${i}
    if [[ -f /install/.$app.lock ]]; then
        echo_progress_start "Reinstalling nginx config for $app"
        /usr/local/bin/swizzin/nginx/$app.sh
        echo_progress_done
    fi
done

fcgis=($(find /etc/nginx -type f -exec grep -l "fastcgi_pass unix:/run/php" {} \;))
for fix in "${fcgis[@]}"; do
    sed -i "s|fastcgi_pass .*|fastcgi_pass unix:/run/php-fpm/php-fpm.sock;|g" "$fix"
done

pac_install --only-upgrade nginx

systemctl enable php-fpm.service >> "$log" 2>&1 || true
restart_php_fpm
systemctl reload nginx
