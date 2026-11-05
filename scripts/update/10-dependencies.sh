#!/bin/bash
# Ensures that global Swizzin dependencies are installed on Arch Linux.

pac_update

# Space-separated list of required GLOBAL SWIZZIN dependencies (NOT application specific ones)
dependencies="libnewt git sudo curl wget lsof syslog-ng fail2ban apache vnstat tcl base-devel gnupg bc util-linux jq net-tools cracklib unzip cronie psmisc which"

pac_install $dependencies

systemctl enable --now cronie >> "${log}" 2>&1 || true

# Ensure paru AUR helper and _swizzin_aur build user are configured
ensure_paru
aur_install --ignore-errors ccze

#shellcheck source=sources/functions/gcc
. /etc/swizzin/sources/functions/gcc
GCC_Jammy_Upgrade
