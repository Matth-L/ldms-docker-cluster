#!/bin/bash

PID_FILE="/tmp/ldmsd_${SLURM_JOBID}.pid"

# 2. Check if the file exists
if [ -f "$PID_FILE" ]; then
    # Read the PID
    TARGET_PID=$(cat "$PID_FILE")

    # Check if the process is actually running
    if ps -p "$TARGET_PID" > /dev/null; then
        kill "$TARGET_PID"
    fi

    rm "$PID_FILE"
fi

exit 0