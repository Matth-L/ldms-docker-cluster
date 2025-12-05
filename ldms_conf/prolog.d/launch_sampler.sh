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

ldmsd -x sock:10001 \
    -c /ldms_conf/slurm-sampler.conf &