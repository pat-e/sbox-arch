#!/bin/bash
# swizzin dashboard installer
# Author: liara
# Copyright (C) 2020 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#! /bin/bash

if [[ ! -f /install/.nginx.lock ]]; then
    echo_warn "This package requires nginx to be installed!"
    if ask "Install nginx?" Y; then
        bash /usr/local/bin/swizzin/install/nginx.sh
    else
        exit 1
    fi
fi

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv

master=$(_get_master_username)

useradd -r swizzin -s /usr/bin/nologin > /dev/null 2>&1

LIST='python uv git acl'
pac_install $LIST

python3_venv swizzin swizzin

echo_progress_start "Cloning panel"
git clone https://github.com/liaralabs/swizzin_dashboard.git /opt/swizzin >> ${log} 2>&1
echo_progress_done "Panel cloned"

echo_progress_start "Installing python dependencies via uv"
uv_pip_install /opt/.venv/swizzin --upgrade pip wheel 'setuptools<81' >> ${log} 2>&1
uv_pip_install /opt/.venv/swizzin -r /opt/swizzin/requirements.txt >> ${log} 2>&1
echo_progress_done

echo_progress_start "Setting permissions"
chown -R swizzin: /opt/swizzin
chown -R swizzin: /opt/.venv/swizzin
setfacl -m g:swizzin:rx /home/*
echo_progress_done

echo_progress_start "Configuring panel"
if [[ -f /install/.deluge.lock ]]; then
    touch /install/.delugeweb.lock
fi

if [[ $master == $(id -nu 1000) ]]; then
    :
else
    echo "ADMIN_USER = '$master'" >> /opt/swizzin/swizzin.cfg
fi
echo_progress_done

# Checking nginx existence is the first thing that happens in the script
echo_progress_start "Configuring nginx"
bash /usr/local/bin/swizzin/nginx/panel.sh
systemctl reload nginx
echo_progress_done

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/panel.service << EOS
[Unit]
Description=swizzin panel service
After=nginx.service

[Service]
Type=simple
User=swizzin

ExecStart=/opt/.venv/swizzin/bin/python swizzin.py
WorkingDirectory=/opt/swizzin
Restart=on-failure
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
EOS

cat > /etc/sudoers.d/panel << EOSUD
#Defaults  env_keep -="HOME"
Defaults:swizzin !logfile
Defaults:swizzin !syslog
Defaults:swizzin !pam_session

Cmnd_Alias   CMNDS = /usr/bin/quota
Cmnd_Alias   SYSDCMNDS = /bin/systemctl start *, /bin/systemctl stop *, /bin/systemctl restart *, /bin/systemctl disable *, /bin/systemctl enable *

swizzin     ALL = (ALL) NOPASSWD: CMNDS, SYSDCMNDS
EOSUD

systemctl enable -q --now panel >> ${log} 2>&1
echo_progress_done "Panel started"

echo_success "Panel installed"
touch /install/.panel.lock
