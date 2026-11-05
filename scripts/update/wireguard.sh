#!/bin/bash

if [[ -f /install/.wireguard.lock ]]; then
    pac_install wireguard-tools
fi
