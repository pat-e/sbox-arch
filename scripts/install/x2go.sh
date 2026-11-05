#!/bin/bash
#
# x2go installer
#
# Author: liara
#
# swizzin Copyright (C) 2019
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

distribution=$(_os_distro)
release=$(_os_codename)
echo_info "Please note that both xfce4 and x2go are VERY heavy packages to install and will take quite some time. If you're concerned whether the install is still running or not, please inspect the swizzin log through another session by running \`tail -f /root/logs/swizzin.log\`"

pac_install xfce4 xfce4-goodies xorg-server x2goserver pulseaudio
#disable lightdm if installed
systemctl disable --now lightdm >> ${log} 2>&1 || true
systemctl enable --now x2goserver >> ${log} 2>&1 || true

touch /install/.x2go.lock
