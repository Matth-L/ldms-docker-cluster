Back to the main README.md : [here](../README.md)

# Gathering metrics with a `.csv` (manually)

Logically, the aggregator will always be up and listening to all the node. The aggregator will be launched by `slurmctld`. Then the goal will be to launch the daemon LDMS on each compute node, for this example, only c1 will launch LDMSd, then we'll just need to check if the data are well stored.

## Step 1 : Launching the aggregator

Connect to `slurmctld` :
```sh
docker exec -it slurmctld bash
```

Then, you'll need to export LDMS libs :
```sh
OVIS=/opt/ovis
export LD_LIBRARY_PATH=$OVIS/lib:$LD_LIBRARY_PATH
export LDMSD_PLUGIN_LIBPATH=$OVIS/lib/ovis-ldms
export ZAP_LIBPATH=$OVIS/lib/ovis-ldms
export PATH=$OVIS/sbin:$OVIS/bin:$PATH
export PYTHONPATH=$OVIS/lib/python3.9/site-packages

ldmsd -x sock:20001 -c /shared/ldms_conf/agg.conf &
```

This launches the aggregator on the port 20001 with the config file [`agg.conf`](./slurm/scripts/agg.conf). This scripts gather metrics and put them in `/data/store/store_csv/` in `slurmctld`.

To check if the data are collected, use this command:

```sh
ldms_ls -h ${HOSTNAME} -x sock -p 20001 -v
```

## Step 2 : Manually launch the sampler

Now that the aggregator is working. Connect to a compute node :

```sh
docker exec -it c1 bash
```

Launch the sampler, that will stream the data on the port 10001 with the config file [`sampler.conf`](./slurm/scripts/sampler.conf). This gathers metrics from `c1`, the instance name is empty because it expects slurm data, but it still works.

```sh
OVIS=/opt/ovis
export LD_LIBRARY_PATH=$OVIS/lib:$LD_LIBRARY_PATH
export LDMSD_PLUGIN_LIBPATH=$OVIS/lib/ovis-ldms
export ZAP_LIBPATH=$OVIS/lib/ovis-ldms
export PATH=$OVIS/sbin:$OVIS/bin:$PATH
export PYTHONPATH=$OVIS/lib/python3.9/site-packages

ldmsd -x sock:10001 -c /shared/ldms_conf/sampler.conf &
```

Check if this command works with :

```sh
ldms_ls -h ${HOSTNAME} -x sock -p 10001 -v
```

## Step 3 : Check the aggregator and the `.csv`

```sh
docker exec -it slurmctld bash

ls -l /shared/data/store/store_csv/
```

Each folder contains the metrics from each type :
```
[root@slurmctld store_csv]# ls
dstat_store  loadavg_store  meminfo_store  procinterrupts_store  procstat_store  vmstat_store
```
