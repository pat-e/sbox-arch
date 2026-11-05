#!/bin/bash
MASTER=$(cut -d: -f1 < /root/.master.info)
systemctl stop -q syncthing@${MASTER}
pac_remove --purge syncthing
rm /etc/systemd/system/syncthing@.service
rm -f /etc/nginx/apps/syncthing.conf
systemctl reload nginx
rm /install/.syncthing.lock
