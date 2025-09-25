#!/bin/sh

if [ "$SENDER" = "front_app_switched" ]; then
  ICON="$($CONFIG_DIR/plugins/icon_map.sh "$INFO")"
  sketchybar --set "$NAME" label="$INFO" icon="$ICON"
fi
