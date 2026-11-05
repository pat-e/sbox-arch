#!/bin/bash
if [[ -f /install/.calibre.lock ]]; then
    # check if xcb-util-cursor is installed
    if ! check_installed xcb-util-cursor; then
        echo_info "Installing new calibre dependencies"
        pac_install xcb-util-cursor
    fi
fi
