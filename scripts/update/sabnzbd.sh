#!/bin/bash

if [[ -f /install/.sabnzbd.lock ]]; then
    if [[ -f /etc/systemd/system/sabnzbd@.service ]]; then
        echo_progress_start "Updating SABnzbd to use pyenv"
        user=$(_get_master_username)
        codename=$(_os_codename)
        #shellcheck source=sources/functions/pyenv
        . /etc/swizzin/sources/functions/pyenv
        active=$(systemctl is-active sabnzbd@${user})
        systemctl disable -q --now sabnzbd@${user} >> "${log}" 2>&1
        LIST='par2cmdline p7zip python2 libxml2 libxslt glib2 dbus'
        pac_install $LIST
        python_getpip

        python2_venv ${user} sabnzbd

        PIP='wheel setuptools dbus-python configobj feedparser pgi lxml utidylib yenc sabyenc cheetah pyOpenSSL'
        /opt/.venv/sabnzbd/bin/pip install $PIP >> "${log}" 2>&1
        chown -R ${user}: /opt/.venv/sabnzbd

        mkdir /home/${user}/.config > /dev/null 2>&1
        chown ${user}: /home/${user}/.config

        mv /home/${user}/.sabnzbd /home/${user}/.config/sabnzbd
        mv /home/${user}/SABnzbd /opt/sabnzbd

        cat > /etc/systemd/system/sabnzbd.service << SABSD
[Unit]
Description=Sabnzbd
Wants=network-online.target
After=network-online.target

[Service]
User=${user}
ExecStart=/opt/.venv/sabnzbd/bin/python /opt/sabnzbd/SABnzbd.py --config-file /home/${user}/.config/sabnzbd/sabnzbd.ini --logging 1
WorkingDirectory=/opt/sabnzbd
Restart=on-failure

[Install]
WantedBy=multi-user.target

SABSD
        systemctl daemon-reload
        rm /etc/systemd/system/sabnzbd@.service

        if [[ $active == "active" ]]; then
            systemctl enable -q --now sabnzbd 2>&1 | tee -a "${log}"
        fi
        echo_done
    fi
fi
