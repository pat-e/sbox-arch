#! /bin/bash
# shellcheck disable=SC2024
# Webmin installer
# flying_sausages for swizzin 2020

_install_webmin() {
    echo_progress_start "Installing Webmin from AUR"
    aur_install webmin
    systemctl enable --now webmin >> "${log}" 2>&1 || true
    echo_progress_done "Webmin installed"
}

_install_webmin
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /etc/swizzin/scripts/nginx/webmin.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Webmin will run on port 10000"
fi

echo_success "Webmin installed"
echo_info "Please use any account with sudo permissions to log in"

touch /install/.webmin.lock
