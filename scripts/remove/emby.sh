#!/bin/bash
# Removal script for emby

systemctl disable --now -q emby-server
pac_remove --purge emby-server
rm -rf /etc/nginx/apps/emby.conf
rm -rf /install/.emby.lock
