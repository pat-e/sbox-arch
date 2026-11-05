#!/bin/bash

if [[ -f /install/.bazarr.lock ]]; then
    codename=$(_os_codename)
    user=$(cut -d: -f1 < /root/.master.info)
    #shellcheck source=sources/functions/pyenv
    . /etc/swizzin/sources/functions/pyenv
    if ! grep -q .venv /etc/systemd/system/bazarr.service; then
        echo_progress_start "Updating bazarr to python3 virtualenv via uv"
        pac_install python uv
        python3_venv ${user} bazarr
        mv /home/${user}/bazarr /opt
        uv_pip_install /opt/.venv/bazarr -r /opt/bazarr/requirements.txt > /dev/null 2>&1
        chown -R ${user}: /opt/.venv/bazarr
        sed -i "s|ExecStart=.*|ExecStart=/opt/.venv/bazarr/bin/python3 /opt/bazarr/bazarr.py|g" /etc/systemd/system/bazarr.service
        sed -i "s|WorkingDirectory=.*|WorkingDirectory=/opt/bazarr|g" /etc/systemd/system/bazarr.service
        systemctl daemon-reload
        systemctl try-restart bazarr
        echo_progress_done
    fi

    if ! grep -q numpy <(uv pip freeze --python /opt/.venv/bazarr/bin/python 2> /dev/null); then
        echo_progress_start "Updating bazarr dependencies"
        uv_pip_install /opt/.venv/bazarr -r /opt/bazarr/requirements.txt > /dev/null 2>&1
        chown -R ${user}: /opt/.venv/bazarr
        systemctl try-restart bazarr
        echo_progress_done
    fi

    # Switching deployment type from git-based to release archive
    if [ -d /opt/bazarr/.git ]; then
        echo_progress_start "Updating bazarr to new structure"
        active=$(systemctl is-active bazarr)
        if [[ $active == "active" ]]; then
            systemctl stop bazarr
        fi

        wget https://github.com/morpheus65535/bazarr/releases/latest/download/bazarr.zip -O /tmp/bazarr.zip >> $log 2>&1 || {
            echo_error "Failed to download"
            exit 1
        }

        cp -R /opt/bazarr/data /tmp/bazarr_data
        mv /opt/bazarr/ /tmp/bazarr-bak

        mkdir /opt/bazarr
        unzip /tmp/bazarr.zip -d /opt/bazarr >> $log 2>&1 || {
            echo_error "Failed to extract zip"
            mv /tmp/bazarr-bak /opt/bazarr/
            exit 1
        }
        rm /tmp/bazarr.zip

        uv_pip_install /opt/.venv/bazarr -r /opt/bazarr/requirements.txt >> $log 2>&1 || {
            echo_error "Dependencies failed to install"
            exit 1
        }
        chown -R "${user}": /opt/.venv/bazarr

        cp -R /tmp/bazarr_data /opt/bazarr/data
        chown -R "${user}": /opt/bazarr

        if [[ $active == "active" ]]; then
            systemctl start bazarr
        fi
        echo_progress_done "Bazarr updated"
    fi
fi
