#!/bin/bash
if [[ -f /install/.sonarr.lock ]]; then
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/sonarr

    #Move sonarr installs to .net
    if grep -q "ExecStart=/usr/bin/mono" /etc/systemd/system/sonarr.service; then
        echo_info "Moving Sonarr from mono to .Net"
        #shellcheck source=sources/functions/utils
        . /etc/swizzin/sources/functions/utils
        [[ -z $sonarrOwner ]] && sonarrOwner=$(_get_master_username)

        if [[ $(_sonarr_version) = "mono-v3" ]]; then
            echo_progress_start "Downloading release files"
            urlbase="https://services.sonarr.tv/v1/download/main/latest?version=4&os=linux"
            case "$(_os_arch)" in
                "amd64") dlurl="${urlbase}&arch=x64" ;;
                "armhf") dlurl="${urlbase}&arch=arm" ;;
                "arm64") dlurl="${urlbase}&arch=arm64" ;;
                *)
                    echo_error "Arch not supported"
                    exit 1
                    ;;
            esac
            if ! curl "$dlurl" -L -o /tmp/sonarr.tar.gz >> "$log" 2>&1; then
                echo_error "Download failed, exiting"
                exit 1
            fi
            echo_progress_done "Release downloaded"

            isactive=$(systemctl is-active sonarr)
            echo_log_only "Sonarr was $isactive"
            [[ $isactive == "active" ]] && systemctl stop sonarr -q

            echo_progress_start "Removing old binaries"
            rm -rf /opt/Sonarr/
            if check_installed mono; then
                pacman -D --asdeps mono >> "$log" 2>&1 || true
            fi
            echo_progress_done "Binaries removed"

            echo_progress_start "Extracting archive"
            tar -xvf /tmp/sonarr.tar.gz -C /opt >> "$log" 2>&1
            chown -R "$sonarrOwner":"$sonarrOwner" /opt/Sonarr
            echo_progress_done "Archive extracted"

            echo_progress_start "Fixing Sonarr systemd service"
            # Watch out! If this sed runs, the updater will not trigger anymore. keep this at the bottom.
            sed -i "s|ExecStart=/usr/bin/mono --debug /opt/Sonarr/Sonarr.exe|ExecStart=/opt/Sonarr/Sonarr|g" /etc/systemd/system/sonarr.service
            systemctl daemon-reload
            [[ $isactive == "active" ]] && systemctl start sonarr -q
            echo_progress_done "Service fixed and restarted"
            echo_success "Sonarr upgraded to .Net"

            if [[ -f /install/.nginx.lock ]]; then
                echo_progress_start "Upgrading nginx config for Sonarr"
                bash /etc/swizzin/scripts/nginx/sonarr.sh
                systemctl reload nginx -q
                echo_progress_done "Nginx conf for Sonarr upgraded"
            fi

        elif [[ $(_sonarr_version) = "mono-v2" ]]; then
            echo_warn "Sonarr v2 is EOL and not supported. Please upgrade your Sonarr to v4. An attempt will be made to migrate to .NET on the next \`box update\` run"
            echo_docs "applications/sonarr#migrating-to-v3-on-net-core"
        fi
    else
        echo_log_only "Sonarr's service is not pointing to mono"
    fi
    #Mandatory SSL Port change for Readarr
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    app_name="sonarr"
    if [ -z "$sonarrOwner" ]; then
        if ! sonarrOwner="$(swizdb get $app_name/owner)"; then
            sonarrOwner=$(_get_master_username)
            ownerToSetInDB='True'
        fi
    else
        ownerToSetInDB='True'
    fi

    app_configfile="/home/$sonarrOwner/.config/Sonarr/config.xml"

    if [[ $ownerToSetInDB = 'True' ]]; then
        if [ -e "$app_configfile" ]; then
            echo_info "Setting ${app_name^} owner = $sonarrOwner in SwizDB"
            swizdb set "$app_name/owner" "$sonarrOwner"
        else
            echo_error "${app_name^} config file for sonarr owner does not exist in expected location.
We are checking for $app_configfile.
If the user here is incorrect, please run \`sonarrOwner=<user> box update\`.
${app_name^} updater is exiting, please try again later."
            exit 1
        fi
    else
        echo_log_only "Sonarr owner $sonarrOwner apparently did not need an update"
    fi

    if [[ -f /install/.nginx.lock ]]; then
        if grep -q "8989/sonarr" /etc/nginx/apps/sonarr.conf || ! grep -q "proxy_read_timeout" /etc/nginx/apps/sonarr.conf; then
            echo_progress_start "Upgrading nginx config for Sonarr"
            bash /etc/swizzin/scripts/nginx/sonarr.sh
            systemctl reload nginx -q
            echo_progress_done "Nginx config for Sonarr upgraded"
        fi
    fi
fi

if check_installed nzbdrone; then
    v2present=true
    echo_warn "Sonarr v2 is obsolete and end-of-life. Please upgrade your Sonarr to v3 using \`box upgrade sonarr\`."
fi
if [[ -f /install/.sonarr.lock ]] && [[ $v2present == "true" ]]; then
    echo_info "box package sonarr is being renamed to sonarrold"
    #update lock file
    rm /install/.sonarr.lock
    if [[ -f /install/.nginx.lock ]]; then
        mv /etc/nginx/apps/sonarr.conf /etc/nginx/apps/sonarrold.conf
        systemctl reload nginx
    fi
    touch /install/.sonarrold.lock
fi
if [[ -f /install/.sonarrv3.lock ]]; then
    echo_info "box package sonarrv3 is being renamed to sonarr as it has been released as stable"
    #upgrade sonarr v3 lock
    if [[ -f /install/.nginx.lock ]]; then
        mv /etc/nginx/apps/sonarrv3.conf /etc/nginx/apps/sonarr.conf
        systemctl reload nginx
    fi
    rm /install/.sonarrv3.lock
    touch /install/.sonarr.lock
fi
if [[ -f /install/.sonarr.lock ]] && check_installed sonarr; then
    echo_info "Migrating Sonarr away from package manager!"
    echo_progress_start "Migrating Sonarr away from package manager"
    isActive=$(systemctl is-active sonarr)
    isEnabled=$(systemctl is-enabled sonarr)
    cp -a /usr/lib/sonarr/bin /opt/Sonarr
    if [[ ! -f /usr/lib/systemd/system/sonarr.service ]]; then
        echo_error "A required file for the update could not be found: /usr/lib/systemd/system/sonarr.service . Is your current Sonarr installation in a proper state?"
        exit 1
    fi
    cp /usr/lib/systemd/system/sonarr.service /etc/systemd/system
    user=$(grep User= /etc/systemd/system/sonarr.service | cut -d= -f2)
    if [[ -z ${user} ]]; then
        echo_error "Could not determine the owner of Sonarr"
        exit 1
    fi
    echo_info "Moving config to '/home/${user}/.config/Sonarr'"
    mv /home/${user}/.config/sonarr /home/${user}/.config/Sonarr

    #Remove comments
    sed -i '/^#/d' /etc/systemd/system/sonarr.service
    #Update binary location
    sed -i 's|/usr/lib/sonarr/bin|/opt/Sonarr|g' /etc/systemd/system/sonarr.service
    sed -i "s|/home/${user}/.config/sonarr|/home/${user}/.config/Sonarr|g" /etc/systemd/system/sonarr.service

    #Mark depends as manually installed
    LIST='mono sqlite mediainfo'

    pac_install ${LIST}

    pac_remove --purge sonarr
    rm -rf /var/lib/sonarr
    rm -rf /usr/lib/sonarr
    systemctl daemon-reload

    #Restart sonarr because package removal stops it
    if [[ $isActive == "active" ]]; then
        systemctl start sonarr
    fi

    #Update broken symlink to old service
    if [[ $isEnabled == "enabled" ]]; then
        systemctl enable sonarr >> ${log} 2>&1
    fi
    echo_progress_done
fi
