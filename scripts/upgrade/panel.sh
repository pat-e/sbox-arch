#!/bin/bash
# Temporary upgrade script for the panel until panel becomes more self-sufficient

if [[ -f /install/.panel.lock ]]; then
    if ! check_installed acl; then
        echo_progress_start "Modifying ACLs for swizzin group to prevent panel issues"
        pac_install acl
        setfacl -m g:swizzin:rx /home/*
        echo_progress_done
    fi
    echo_progress_start "Downloading latest panel commits"
    sudo -u swizzin git -C /opt/swizzin pull >> ${log} 2>&1 || { PANELRESET=1; }
    if [[ $PANELRESET == 1 ]]; then
        echo_warn "Working around unclean git repo"
        sudo -u swizzin git -C /opt/swizzin fetch origin master >> ${log} 2>&1
        cp -a /opt/swizzin/core/custom /opt/swizzin/core/custom.tmp
        sudo -u swizzin git -C /opt/swizzin reset --hard origin/master >> ${log} 2>&1
        mv /opt/swizzin/core/custom.tmp/* /opt/swizzin/core/custom/ >> ${log} 2>&1
        rm -rf opt/swizzin/core/custom.tmp
    fi
    echo_progress_done "Commits pulled"
    echo_progress_start "Checking for new panel dependencies via uv"
    #shellcheck source=sources/functions/pyenv
    . /etc/swizzin/sources/functions/pyenv
    if ! /opt/.venv/swizzin/bin/python /opt/swizzin/tests/test_requirements.py >> ${log} 2>&1; then
        uv_pip_install /opt/.venv/swizzin --upgrade pip wheel 'setuptools<81' >> ${log} 2>&1
        uv_pip_install /opt/.venv/swizzin -r /opt/swizzin/requirements.txt >> ${log} 2>&1
        chown -R swizzin: /opt/.venv/swizzin
    fi
    echo_progress_done "Depends up-to-date"
    echo_progress_start "Restarting Panel"
    systemctl restart panel
    echo_progress_done "Done!"
fi
