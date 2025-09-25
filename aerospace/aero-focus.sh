#!/bin/zsh
sketchybar --trigger aerospace_workspace_change AEROSPACE_FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE AEROSPACE_PREV_WORKSPACE=$AEROSPACE_PREV_WORKSPACE

focused=$(aerospace list-windows --focused --format "%{app-bundle-id}")
if [[ "$focused" == "org.gnu.Emacs" ]]; then
    aerospace mode emacs
else
    aerospace mode main
fi
echo "" >>$LOG

