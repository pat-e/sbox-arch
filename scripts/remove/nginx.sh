#!/bin/bash

systemctl stop -q nginx

pac_remove --purge nginx nginx-mod-fancyindex php php-fpm php-gd php-intl php-sqlite fcgi

rm -rf /etc/nginx
rm -rf /etc/php

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
rm_if_exists "/srv/rutorrent"
rm_if_exists "/install/.rutorrent.lock"

rm_if_exists "/srv/panel"
rm_if_exists "/etc/sudoers.d/panel"
rm_if_exists "/etc/cron.d/set_interface"

# rm_if_exists "/srv/organizr"
rm_if_exists "/install/.organizr.lock"

rm /install/.nginx.lock
