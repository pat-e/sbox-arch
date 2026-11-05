#!/bin/bash
# Simple tool to upgrade emby on Arch Linux

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [[ ! -f /install/.emby.lock ]]; then
    echo_error "Emby does not appear to be installed!"
    exit 1
fi

echo_info "Upgrading Emby"
if check_installed emby-server-bin; then
    aur_install --only-upgrade emby-server-bin
else
    pac_install --only-upgrade emby-server
fi
systemctl try-restart emby-server >> "$log" 2>&1 || true
