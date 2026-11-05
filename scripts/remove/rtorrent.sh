#!/bin/bash
users=($(cut -d: -f1 < /etc/htpasswd))

if [[ -f /install/.rutorrent.lock ]]; then
    if ! ask "This will remove ruTorrent. Continue?" Y; then
        exit 0
    fi
fi
for u in ${users}; do
    systemctl disable -q rtorrent@${u}
    systemctl stop -q rtorrent@${u}
    rm -f /home/${u}/.rtorrent.rc
done

#shellcheck source=sources/functions/rtorrent
. /etc/swizzin/sources/functions/rtorrent
echo_progress_start "Removing old rTorrent binaries and libraries ... "
remove_rtorrent
echo_progress_done

for a in rutorrent; do
    if [[ -f /install/.$a.lock ]]; then
        /usr/local/bin/swizzin/remove/$a.sh
    fi
done
rm /etc/systemd/system/rtorrent@.service
rm /install/.rtorrent.lock
