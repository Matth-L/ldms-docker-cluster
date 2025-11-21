#!/bin/bash

# loading ldms 
OVIS=/opt/ovis                                          
export LD_LIBRARY_PATH=$OVIS/lib:$LD_LIBRARY_PATH       
export LDMSD_PLUGIN_LIBPATH=$OVIS/lib/ovis-ldms         
export ZAP_LIBPATH=$OVIS/lib/ovis-ldms                  
export PATH=$OVIS/sbin:$OVIS/bin:$PATH        
export PYTHONPATH=$OVIS/lib/python3.9/site-packages

pid=$(cat /tmp/ldms_${HOSTNAME}.pid 2>/dev/null)
if [ -n "$pid" ]; then
    kill "$pid" 2>/dev/null && rm -f /tmp/ldms_${HOSTNAME}.pid
fi