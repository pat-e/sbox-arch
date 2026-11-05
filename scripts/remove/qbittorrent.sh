#!/bin/bash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/libtorrent
. /etc/swizzin/sources/functions/libtorrent

users=($(_get_user_list))
for user in ${users[@]}; do
    systemctl disable --now -q qbittorrent@${user}
    rm -rf /home/${user}/.config/qbittorrent
done
rm -f /etc/systemd/system/qbittorrent@.service
pac_remove --purge qbittorrent-nox

if [[ ! -f /install/.deluge.lock ]]; then
    pac_remove --purge libtorrent-rasterbar
fi

if [[ -f /install/.nginx.lock ]]; then
    systemctl reload nginx
    rm -f /etc/nginx/apps/qbittorrent.conf
    rm -f /etc/nginx/conf.d/*.qbittorrent.conf
fi
rm /install/.qbittorrent.lock
