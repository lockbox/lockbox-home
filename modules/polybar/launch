#!/usr/bin/env bash

# a nicer killall -q polybar
polybar-msg cmd quit

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.01; done
 
# Start a polybar instance on each monitor,
# - using default config location ~/.config/polybar/config
# - with a log location of /tmp/polybar-<monitor idx>.log
polybar_id=0
for m in $(polybar --list-monitors | cut -d":" -f1); do
    LOG_FILE="/tmp/polybar-$polybar_id.log"
    echo "---" >> $LOG_FILE
    echo "[launch.sh] Launching polybar on monitor $m" >> $LOG_FILE

    # MONITOR: choose the monitor for polybar to be displayed on
    # --reload: reload config when files are updated
    # `main-polybar`: name of the bar in the polybar config
    MONITOR=$m polybar --reload main-polybar 2>&1 | tee -a $LOG_FILE > /dev/null & disown

    # inc monitor index
    (( polybar_id++ ))
done

echo "Polybar spawned"

