#!/usr/bin/env bash

if [ ! -f /install/.calibre.lock ]; then
    echo_error "Calibre is not installed"
    exit 1
fi

if ! check_installed libglvnd; then pac_install libglvnd; fi
if ! check_installed xcb-util-cursor; then pac_install xcb-util-cursor; fi

case "$(_os_arch)" in
    amd64)
        wget https://download.calibre-ebook.com/linux-installer.sh -O /tmp/calibre-installer.sh >> $log 2>&1
        if ! bash /tmp/calibre-installer.sh install_dir=/opt >> $log 2>&1; then
            echo_error "failed to upgrade calibre"
            exit 1
        fi
        ;;
    *)
        pac_install --only-upgrade calibre
        ;;
esac
