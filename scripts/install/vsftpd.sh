#!/bin/bash
# vsftpd installer
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

pac_install vsftpd openssl

echo_progress_start "Configuring vsftpd"
mkdir -p /etc/ssl/certs /etc/ssl/private /var/run/vsftpd/empty
if [[ ! -f /etc/ssl/certs/ssl-cert-snakeoil.pem ]] || [[ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ]]; then
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
        -out /etc/ssl/certs/ssl-cert-snakeoil.pem \
        -subj "/CN=localhost" >> $log 2>&1
    chmod 600 /etc/ssl/private/ssl-cert-snakeoil.key
fi
cat > /etc/vsftpd.conf << VSC
listen=NO
listen_ipv6=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
force_dot_files=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
utf8_filesystem=YES
require_ssl_reuse=NO
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=YES
pam_service_name=vsftpd
secure_chroot_dir=/var/run/vsftpd/empty

#ascii_upload_enable=YES
#ascii_download_enable=YES
#ftpd_banner=Welcome to blah FTP service.

#############################################
#Uncomment these lines to enable FXP support#
#############################################
#pasv_promiscuous=YES
#port_promiscuous=YES

###################
#Set a custom port#
###################
#listen_port=
VSC

# Check for LE cert, and copy it if available.
# shellcheck source=sources/functions/letsencrypt
. /etc/swizzin/sources/functions/letsencrypt
le_vsftpd_hook

systemctl enable --now vsftpd >> $log 2>&1
systemctl restart vsftpd
echo_progress_done "Configured vsftpd"

echo_success "Vsftpd installed"
touch /install/.vsftpd.lock
