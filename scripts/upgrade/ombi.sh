#!/bin/bash
if [[ ! -f /install/.ombi.lock ]]; then
    echo_error "Ombi not installed"
    exit 1
fi

echo_progress_start "Upgrading Ombi"
aur_install --only-upgrade ombi
if [[ -f /install/.nginx.lock ]]; then
    bash /etc/swizzin/scripts/nginx/ombi.sh
    systemctl reload nginx
else
    echo_info "Ombi will be running on port 3000"
fi
systemctl try-restart ombi >> "$log" 2>&1 || true
echo_progress_done "Ombi upgraded"
echo_success "Ombi upgraded"
