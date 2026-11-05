#!/bin/bash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

systemctl disable --now jfago -q

rm_if_exists /root/.config/jfa-go
rm_if_exists /opt/jfago
userdel -rf jfago > /dev/null 2>&1

pac_remove --purge jfa-go-bin

rm_if_exists /etc/systemd/system/jfago.service

systemctl daemon-reload -q

if [[ -f /install/.nginx.lock ]]; then
    rm_if_exists /etc/nginx/apps/jfago.conf
    systemctl reload nginx
fi

rm_if_exists /install/.jfago.lock
