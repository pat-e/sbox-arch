#!/bin/bash
username=$(cut -d: -f1 < /root/.master.info)

rm -r /home/$username/Jackett
rm /install/.jackett.lock
rm -r /home/${username}/.config/Jackett

systemctl stop -q jackett@${username}
systemctl disable -q jackett@${username}
rm /etc/systemd/system/jackett@.service
rm -f /etc/nginx/apps/jackett.conf
systemctl reload nginx
