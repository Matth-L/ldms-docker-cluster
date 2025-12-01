#!/bin/bash

# loading ldms
OVIS=/opt/ovis
export LD_LIBRARY_PATH=$OVIS/lib:$LD_LIBRARY_PATH
export LDMSD_PLUGIN_LIBPATH=$OVIS/lib/ovis-ldms
export ZAP_LIBPATH=$OVIS/lib/ovis-ldms
export PATH=$OVIS/sbin:$OVIS/bin:$PATH
export PYTHONPATH=$OVIS/lib/python3.9/site-packages

env > /tmp/prolog_env_${SLURM_JOBID}.txt
id > /tmp/prolog_user.txt

setsid ldmsd -x sock:10001 \
    -c /etc/slurm/scripts/sampler.conf \
    -l /tmp/ldms_${SLURM_JOB_USER}_${HOSTNAME}.log \
    -r /tmp/ldms_${HOSTNAME}.pid \
    >/tmp/ldms_prolog_${HOSTNAME}.out 2>&1 < /dev/null &
exit 0