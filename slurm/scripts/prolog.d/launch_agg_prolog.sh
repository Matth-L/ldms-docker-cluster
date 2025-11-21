#!/bin/bash

# loading ldms 
OVIS=/opt/ovis                                          
export LD_LIBRARY_PATH=$OVIS/lib:$LD_LIBRARY_PATH       
export LDMSD_PLUGIN_LIBPATH=$OVIS/lib/ovis-ldms         
export ZAP_LIBPATH=$OVIS/lib/ovis-ldms                  
export PATH=$OVIS/sbin:$OVIS/bin:$PATH        
export PYTHONPATH=$OVIS/lib/python3.9/site-packages

ldmsd -x sock:20001\
      -c /etc/slurm/scripts/agg_prolog.conf \
      -l /tmp/ldms_${SLURM_JOBID}.log \
      -r /tmp/ldms_${SLURM_JOBID}.pid 


ldms_ls -h ${HOSTNAME} -x sock -p 20001 -v
