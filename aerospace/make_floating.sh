#!/bin/zsh

# move focused window to "F"-loating workspace
aerospace move-node-to-workspace F --focus-follows-window

# change layout to floating
focused_window_id=$(aerospace list-windows --focused --format %{window-id})
aerospace layout --window-id $focused_window_id floating

# update sketchybar
sketchybar --trigger aerospace_workspace_change AEROSPACE_FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE AEROSPACE_PREV_WORKSPACE=$AEROSPACE_PREV_WORKSPACE
