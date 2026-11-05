#!/bin/bash

# Nginx configuration for LibreSpeed
# Author - hwcltjn

#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php

if [[ ! -f /etc/nginx/apps/librespeed.conf ]]; then
    cat > /etc/nginx/apps/librespeed.conf << RAP
location /librespeed {
	alias /srv/librespeed;
	client_max_body_size 50M;
	client_body_buffer_size 128k;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$request_filename;
        include fastcgi_params;
  }
}
RAP
fi
