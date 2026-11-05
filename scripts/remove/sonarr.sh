#!/bin/bash

user=$(grep User= /etc/systemd/system/sonarr.service | cut -d= -f2)
if ask "Would you like to purge the configuration?" Y; then
    if [[ -d /home/${user}/.config/Sonarr ]]; then
        rm -rf "/home/${user}/.config/Sonarr"
    fi
fi
rm -rf /opt/Sonarr
if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/sonarr.conf
    systemctl reload nginx >> "$log" 2>&1
fi

systemctl disable --now -q sonarr
pac_autoremove
rm -f /etc/systemd/system/sonarr.service

rm /install/.sonarr.lock
