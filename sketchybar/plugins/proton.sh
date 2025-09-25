#!/bin/bash

source "$HOME/.config/sketchybar/icons.sh"

# Check if Proton VPN is running and connected
if pgrep -x "ProtonVPN" > /dev/null; then
    # Check connection status via network interface or API
    # Method 1: Check for VPN interface
    if ifconfig | grep -q "utun"; then
        ICON="🔒"
        LABEL="VPN"
        COLOR=$GREEN
    else
        ICON="🔓"
        LABEL="OFF"
        COLOR=$RED
    fi
else
    ICON="🔓"
    LABEL="OFF"
    COLOR=$RED
fi

sketchybar --set $NAME icon="$ICON" label="$LABEL" icon.color="$COLOR"