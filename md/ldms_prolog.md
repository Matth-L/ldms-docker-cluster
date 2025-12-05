# Gathering metrics from user's job

Logically, the aggregator will always be up and listening to all the node. The aggregator will be launched by `slurmctld`. Then by running the script `launch_job.sh`, one job per user will be launched and the aggregator will receive them

# Step 1 : Launch the aggregator

Connect to `slurmctld` :
```sh
docker exec -it slurmctld bash

OVIS=/opt/ovis
export LD_LIBRARY_PATH=$OVIS/lib:$LD_LIBRARY_PATH
export LDMSD_PLUGIN_LIBPATH=$OVIS/lib/ovis-ldms
export ZAP_LIBPATH=$OVIS/lib/ovis-ldms
export PATH=$OVIS/sbin:$OVIS/bin:$PATH
export PYTHONPATH=$OVIS/lib/python3.9/site-packages


ldmsd -x sock:20001 -c /ldms_conf/agg_kafka.conf -l /tmp/ldms_${HOSTNAME}.log &
# check if the daemon is up
ldms_ls -h ${HOSTNAME} -x sock -p 20001 -v
```

# Step 2 : Creating user in slurm + Launching job

```sh
# Ctrl-D
./scripts/create_user.sh
./scripts/launch_job.sh
# it will say that prolog hung, but it works ? just press Enter
```