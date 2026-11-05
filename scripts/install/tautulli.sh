#!/bin/bash
#
# Tautulli installer
#
# Author             :   QuickBox.IO | liara
# Ported to swizzin by liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv

user=$(cut -d: -f1 < /root/.master.info)

echo_progress_start "Adding user and setting up Tautulli"
useradd --system --no-create-home -g nobody tautulli >> "${log}" 2>&1 || true
echo_progress_done

systempy3_ver=$(get_candidate_version python)

if ver_compare "${systempy3_ver}" lt 3.8.0 || ver_compare "${systempy3_ver}" ge 3.12.0; then
    pac_install git python
    PYENV=True
else
    LIST='git python python-setuptools python-pip'
    pac_install $LIST
fi

case ${PYENV} in
    True)
        pyenv_install
        pyenv_install_version 3.11.3
        pyenv_create_venv 3.11.3 /opt/.venv/tautulli
        chown -R tautulli:nobody /opt/.venv/tautulli
        ;;
    *)
        python3_venv tautulli tautulli
        chown -R tautulli:nobody /opt/.venv/tautulli
        ;;
esac

cd /opt
echo_progress_start "Cloning latest Tautulli repo"
git clone https://github.com/Tautulli/Tautulli.git tautulli >> "${log}" 2>&1
chown -R tautulli:nobody /opt/tautulli
echo_progress_done

echo_progress_start "Enabling Tautulli Systemd configuration"
cat > /etc/systemd/system/tautulli.service << PPY
[Unit]
Description=Tautulli - Stats for Plex Media Server usage
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/.venv/tautulli/bin/python3 /opt/tautulli/Tautulli.py --quiet --daemon --nolaunch --config /opt/tautulli/config.ini --datadir /opt/tautulli
GuessMainPID=no
Type=forking
User=tautulli
Group=nobody

[Install]
WantedBy=multi-user.target
PPY

systemctl enable -q --now tautulli 2>&1 | tee -a $log

echo_progress_done "Tautulli started"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    while [ ! -f /opt/tautulli/config.ini ]; do
        sleep 2
    done
    bash /usr/local/bin/swizzin/nginx/tautulli.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Tautulli will run on port 8181"
fi
touch /install/.tautulli.lock

echo_success "Tautulli installed"
