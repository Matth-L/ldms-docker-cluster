#!/bin/bash

# source
OVIS=/opt/ovis
export LD_LIBRARY_PATH=$OVIS/lib:$LD_LIBRARY_PATH
export LDMSD_PLUGIN_LIBPATH=$OVIS/lib/ovis-ldms
export ZAP_LIBPATH=$OVIS/lib/ovis-ldms
export PATH=$OVIS/sbin:$OVIS/bin:$PATH
export PYTHONPATH=$OVIS/lib/python3.9/site-packages

PID_FILE="/tmp/ldmsd_${SLURM_JOBID}.pid"
LOG_FILE="/tmp/ldmsd_${SLURM_JOBID}.log"


# FILE FORMAT
# The file consists of key-value pairs, one per line, separated by an equals-sign. The recognized keys are:
# JOBID
#     An unsigned integer (up to 64-bit) identifying the job. The number zero is reserved to mean that no job is currently running.
# UID
#     An unsigned integer (up to 64-bit) representing the User ID associated with the job.
# APPID
#     An unsigned integer (up to 64-bit) representing the an application ID for the job.
# USER
#     A string representing the username associated with the job.
# Only the JOBID field is required. The other fields are optional, and will default to zero.


echo JOBID=$SLURM_JOB_ID > /var/run/ldms.jobinfo
echo UID=$SLURM_UID >> /var/run/ldms.jobinfo
echo USER=$SLURM_JOB_USER >> /var/run/ldms.jobinfo

rm -f "$PID_FILE" "$LOG_FILE"

# Execute the ldmsd command inside a separate shell
# ldmsd is run with setsid to isolate its session, and output is logged.
/bin/bash -c "
    setsid ldmsd -x sock:10001 -c /ldms_conf/slurm-sampler.conf
" > "$LOG_FILE" 2>&1 &

sleep 2 # Give ldmsd 2 seconds to start (in case)

LDMSD_PID=$(lsof -t -i :10001)

if [ -z "$LDMSD_PID" ]; then
    echo "ERROR: ldmsd failed to start or bind to port 10001." >> "$LOG_FILE"
    # Exit cleanly to avoid the "Prolog hung" error
    exit 0
fi

echo "$LDMSD_PID" > "$PID_FILE"

exit 0