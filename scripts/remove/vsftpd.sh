#!/bin/bash
#VSFTPd deyeeter by flying sausages for swizzin 2020

pac_remove --purge vsftpd
rm /etc/vsftpd.conf

rm /install/.vsftpd.lock
