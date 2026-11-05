#!/bin/bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
users=($(_get_user_list))
for u in ${users[@]}; do
    systemctl disable --now -q wg-quick@wg$(id -u $u)
    rm -rf /home/$u/.wireguard
done

rm -rf /etc/wireguard/

pac_remove --purge wireguard-tools qrencode

rm /install/.wireguard.lock
