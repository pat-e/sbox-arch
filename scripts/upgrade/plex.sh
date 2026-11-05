#!/bin/bash
# Upgrade plex-media-server on Arch Linux

if [[ ! -f /install/.plex.lock ]]; then
    echo_error "Plex doesn't appear to be installed. What do you hope to accomplish by running this script?"
    exit 1
fi

if check_installed plex-media-server-plexpass; then
    aur_install --only-upgrade plex-media-server-plexpass
else
    aur_install --only-upgrade plex-media-server
fi
systemctl try-restart plexmediaserver >> "$log" 2>&1 || true
