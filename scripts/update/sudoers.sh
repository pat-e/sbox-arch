#!/bin/bash

users=($(cut -d: -f1 < /etc/htpasswd))
master=$(cut -d: -f1 < /root/.master.info)
distribution=$(_os_distro)

if [[ ! -f /etc/sudoers.d/env_keep ]] && [[ $distribution = "Ubuntu" ]]; then
    echo_info "Adding env_keep to sudoers"
    echo 'Defaults  env_keep -="HOME"' > /etc/sudoers.d/env_keep
fi

# TODO this should probably skip the master?
for u in "${users[@]}"; do
    if [[ $u = "$master" ]]; then continue; fi
    USER=${u^^}
    if grep -q ${USER}CMNDS /etc/sudoers.d/$u; then
        echo_info "Fixing sudo permissions for $u"
        sed -i "s/${USER}CMNDS/${USER}CMDS/g" /etc/sudoers.d/$u
    fi
done

if [[ -f /etc/sudoers.d/panel ]]; then
    if grep -q -E "(sed|grep|box|drop_caches|set_interface|pkill|killall|reload|vnstat|ifstat|PACKAGECMNDS)" /etc/sudoers.d/panel; then
        echo_info "Fixing sudo permissions for panel"
        cat > /etc/sudoers.d/panel << SUD
#secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin/swizzin:/usr/local/bin/swizzin/scripts:/usr/local/bin/swizzin/scripts/install:/usr/local/bin/swizzin/scripts/remove:/usr/local/bin/swizzin/panel"
#Defaults  env_keep -="HOME"

# Host alias specification

# User alias specification

# Cmnd alias specification
Cmnd_Alias   CLEANMEM = /usr/local/bin/swizzin/panel/clean_mem
Cmnd_Alias   SYSCMNDS = /usr/local/bin/swizzin/panel/lang/langSelect-*, /usr/local/bin/swizzin/panel/theme/themeSelect-*
Cmnd_Alias   GENERALCMNDS = /usr/sbin/repquota, /bin/systemctl

http     ALL = (ALL) NOPASSWD: CLEANMEM, SYSCMNDS, GENERALCMNDS

SUD
    fi
fi

if [[ ! -f /etc/sudoers.d/wheel ]]; then
    echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
    chmod 0440 /etc/sudoers.d/wheel
fi

if ! groups "$master" | grep -q wheel; then
    echo_log_only "Moving $master to the wheel usergroup"
    usermod -a -G wheel "$master"
    # rm /etc/sudoers.d/swizzin
fi
