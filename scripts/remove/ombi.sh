#!/bin/bash
systemctl disable -q --now ombi
if [[ -f /install/.nginx.lock ]]; then
    rm -f /etc/nginx/apps/ombi.conf
    systemctl reload nginx
fi

if ask "Would you like to purge the configuration?" Y; then
    pac_remove --purge ombi ombi-bin
    if [[ -d /opt/ombi ]]; then
        rm -rf /opt/ombi
        rm -rf /etc/ombi
    fi

    if [[ -d /opt/Ombi ]]; then
        rm -rf /opt/Ombi
        rm -rf /etc/Ombi
    fi
else
    pac_remove ombi ombi-bin
fi

rm /install/.ombi.lock
