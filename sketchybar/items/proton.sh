#!/bin/bash

PROTON=(
  update_freq=30
  icon.font="$ICON_FONT:Regular:20.0"
  icon.color=$TEAL
  background.color=$BG_SEC_COLR
  script="$PLUGIN_DIR/proton.sh"
)

sketchybar --add item proton right \
           --set proton "${PROTON[@]}" \
           --subscribe proton front_app_switched