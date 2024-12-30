#!/bin/bash

TIME=(
  update_freq=10
  icon.drawing=on
  label.padding_left=10
  label.padding_right=6
  background.padding_right=2
  script="$PLUGIN_DIR/time.sh"
)

sketchybar --add item time right \
           --set time "${TIME[@]}"
