#!/bin/bash

# Some systems could be apt-installed, some will have script/built setup
if [[ -e /usr/bin/calibre-uninstall ]]; then
    #TODO shut up and make this go unattended
    /usr/bin/calibre-uninstall
else
    pac_remove --purge calibre
fi

if [ -f /install/.calibrecs.lock ]; then
    bash /etc/swizzin/scripts/remove/calibrecs.sh
fi

rm /install/.calibre.lock

if [ ! -f /install/.calibreweb.lock ] && [ ! -f /install/.calibrecs.lock ]; then
    echo_log_only "Clearing calibre swizdb"
    swizdb clear calibre/library_path
    swizdb clear calibre/library_user
fi
