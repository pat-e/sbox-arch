#!/bin/bash
# Fixes the removal of the skel that was done back in the past
if [[ ! -f /etc/skel/.bashrc ]]; then
    echo_info "Installing /etc/skel/.bashrc"
    mkdir -p /etc/skel
    pacman -S --noconfirm bash >> "$log" 2>&1 || true
    if [[ ! -f /etc/skel/.bashrc ]]; then
        cat > /etc/skel/.bashrc << 'EOF'
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
EOF
    fi
    rm -f /etc/skel/.bashrc.bak

    for d in /home/*/; do
        newbashrc="/etc/skel/.bashrc"
        if [[ ! -f $d.bashrc ]]; then
            cp $newbashrc $d.bashrc
            echo_warn "Installed $d.bashrc. Re-open your terminal or run \`exec \"\$SHELL\"\` to apply the changes."
        else
            if [[ ! $(cmp --silent $d.bashrc $newbashrc) ]]; then
                cp $newbashrc $d.bashrc-default
                echo_warn "Previously, swizzin removed ${d}.bashrc. As the current one is different to the default one, a copy has been placed in your home directory. Please compare them and merge together as you desire."
            fi
        fi
    done
    echo_progress_done
fi
