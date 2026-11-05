#! /bin/bash
# Netdata uninstaller for swizzin

systemctl disable --now -q netdata
pac_remove --purge netdata
rm -rf /etc/netdata

rm -f /etc/nginx/apps/netdata.conf
systemctl reload nginx >> ${log} 2>&1
rm -rf /install/.netdata.lock
