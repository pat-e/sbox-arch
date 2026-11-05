#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)

if [[ ! -f /install/.sabnzbd.lock ]]; then
    echo_error "SABnzbd not detected. Exiting!"
    exit 1
fi

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv
localversion=$(/opt/.venv/sabnzbd/bin/python /opt/sabnzbd/SABnzbd.py --version | grep -m1 SABnzbd | cut -d- -f2)
#latest=$(curl -s https://sabnzbd.org/downloads | grep -m1 Linux | grep download-link-src | grep -oP "href=\"\K[^\"]+")
latestversion=$(github_latest_version sabnzbd/sabnzbd) || {
    echo_error "Failed to query GitHub for latest sabnzbd version"
    exit 1
}
latest="https://github.com/sabnzbd/sabnzbd/archive/refs/tags/${latestversion}.tar.gz"

pyvenv_version=$(/opt/.venv/sabnzbd/bin/python --version | awk '{print $2}')

if ver_compare ${pyvenv_version} lt 3.8.0 && ver_compare ${latestversion} ge 3.5.0; then
    LIST='par2cmdline p7zip python uv libffi openssl glib2 dbus'
    PYENV_REBUILD=True
elif [[ -f /opt/.venv/sabnzbd/bin/python2 ]]; then
    LIST='par2cmdline p7zip python uv libffi openssl glib2 dbus'
    PYENV_REBUILD=True
else
    LIST='par2cmdline p7zip python uv libffi openssl glib2 dbus'
fi
pac_install $LIST

if ver_compare ${localversion:-0.0} lt ${latestversion}; then
    if [[ $PYENV_REBUILD == True ]]; then
        echo_progress_start "Upgrading SABnzbd python virtual environment via uv"
        rm -rf /opt/.venv/sabnzbd
        python3_venv ${user} sabnzbd
        if grep -q python2 /etc/systemd/system/sabnzbd.service; then
            sed -i 's/python2/python/g' /etc/systemd/system/sabnzbd.service
            systemctl daemon-reload
        fi

        echo_progress_done
    fi
    echo_progress_start "Downloading latest source"
    wget -q -O /tmp/sabnzbd.tar.gz "$latest"
    rm -rf /opt/sabnzbd
    mkdir -p /opt/sabnzbd
    tar xzf /tmp/sabnzbd.tar.gz --strip-components=1 -C /opt/sabnzbd >> "$log" 2>&1
    chown -R ${user}: /opt/sabnzbd
    echo_progress_done
    rm -f /tmp/sabnzbd.tar.gz

    echo_progress_start "Installing python requirements via uv"
    if [[ $latestversion =~ ^3\.0\.[1-2] ]]; then
        sed -i "s/feedparser.*/feedparser<6.0.0/g" /opt/sabnzbd/requirements.txt
    fi
    uv_pip_install /opt/.venv/sabnzbd --upgrade pip wheel >> "${log}" 2>&1
    uv_pip_install /opt/.venv/sabnzbd -r /opt/sabnzbd/requirements.txt >> "$log" 2>&1
    chown -R ${user}: /opt/.venv/sabnzbd
    echo_progress_done
    systemctl try-restart sabnzbd
    echo_info "SABnzbd has been upgraded to version ${latestversion}!"
else
    echo_info "Nothing to do! Current version (${localversion}) matches the remote version (${latestversion})"
    exit 0
fi
