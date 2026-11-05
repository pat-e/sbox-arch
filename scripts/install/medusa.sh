#! /bin/bash
# Medusa installer for swizzin
# Author: liara

user=$(cut -d: -f1 < /root/.master.info)
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv

pac_install git openssl python uv unrar
python3_venv ${user} medusa

install_rar

echo_progress_start "Cloning medusa source code"
cd /opt/
git clone https://github.com/pymedusa/Medusa.git medusa >> ${log} 2>&1
chown -R ${user}:${user} medusa
echo_progress_done

echo_progress_start "Installing systemd service"

cat > /etc/systemd/system/medusa.service << MSD
[Unit]
Description=Medusa
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=${user}
Group=${user}
ExecStart=/opt/.venv/medusa/bin/python3 /opt/medusa/SickBeard.py -q --daemon --nolaunch --datadir=/opt/medusa
ExecStop=-/bin/kill -HUP


[Install]
WantedBy=multi-user.target
MSD

systemctl enable -q --now medusa 2>&1 | tee -a $log
echo_progress_done "Medusa started"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/medusa.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Medusa will run on port 8081"
fi

echo_success "Medua installed"
touch /install/.medusa.lock
