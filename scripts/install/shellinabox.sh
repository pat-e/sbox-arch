#!/bin/bash
#
# Swizzin :: Shellinabox installer
# Author: liara
#
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3
#################################################################################

aur_install shellinabox

echo_progress_start "Configuring shellinabox"
systemctl stop shellinabox >> $log 2>&1 || true
rm -rf /etc/init.d/shellinabox
groupadd -f shellinabox
id -u shellinabox > /dev/null 2>&1 || useradd -r -g shellinabox -d /var/lib/shellinabox -s /usr/bin/nologin shellinabox
mkdir -p /var/lib/shellinabox
chown -R shellinabox:shellinabox /var/lib/shellinabox
touch /etc/default/shellinabox

cat > /etc/systemd/system/shellinabox.service << SIAB
[Unit]
Description=Shell in a Box service
After=sshd.service

[Service]
User=root
Type=forking
EnvironmentFile=/etc/default/shellinabox
ExecStart=/usr/bin/shellinaboxd -q --background=/var/run/shellinaboxd.pid -c /var/lib/shellinabox -p 4200 -u shellinabox -g shellinabox \$SHELLINABOX_ARGS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-abort

[Install]
WantedBy=multi-user.target
SIAB

systemctl daemon-reload -q
systemctl enable -q shellinabox 2>&1 | tee -a $log
systemctl start shellinabox >> $log 2>&1
echo_progress_done "Configured and restarted"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/shellinabox.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Shellinabox will run on port 4200"
fi

echo_success "Shellinabox installed"
touch /install/.shellinabox.lock
