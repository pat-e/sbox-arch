#! /bin/bash
# Webmin yeeter
# flying_sausages 2020 for swizzin

pac_remove --purge webmin
rm -rf /etc/webmin

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/webmin.conf
    systemctl reload nginx
fi

rm /install/.webmin.lock
