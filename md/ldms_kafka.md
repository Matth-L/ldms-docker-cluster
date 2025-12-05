Back to the main README.md : [here](../README.md)

# Gathering metrics with kafka (manually)

Logically, the aggregator will always be up and listening to all the node. The aggregator will be launched by `slurmctld`. Then the goal will be to launch the daemon LDMS on each compute node, for this example, only c1 will launch LDMSd, then we'll just need to check if the metrics are sent to kafka.

# Step 1 : Launch the aggregator

Connect to `slurmctld` :
```sh
docker exec -it slurmctld bash
```

Then, you'll need to export LDMS libs and launch the aggregator :
```sh
OVIS=/opt/ovis
export LD_LIBRARY_PATH=$OVIS/lib:$LD_LIBRARY_PATH
export LDMSD_PLUGIN_LIBPATH=$OVIS/lib/ovis-ldms
export ZAP_LIBPATH=$OVIS/lib/ovis-ldms
export PATH=$OVIS/sbin:$OVIS/bin:$PATH
export PYTHONPATH=$OVIS/lib/python3.9/site-packages


ldmsd -x sock:20001 -c /ldms_conf/agg_kafka.conf &

# check if the daemon is up
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


ldmsd -x sock:10001 -c /ldms_conf/sampler.conf &

# check if the daemon is up
ldms_ls -h ${HOSTNAME} -x sock -p 10001 -v
```

# Step 3 : Connect to Kafka broker and consume the data


Connect to the broker :
```sh
docker exec -it broker bash
```

Get the broker list :
```sh
/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server broker:29092
```

This gives me :

```
broker:/$ /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server broker:29092
dstat_d61917b
loadavg_8be3781
meminfo_ef957a7
procinterrupts_b5a2941
procstat2_78935b2
vmstat_cea2f7e
```

Then, the one you want to consume :

```sh
/opt/kafka/bin/kafka-console-consumer.sh --topic vmstat_cea2f7e --from-beginning --bootstrap-server broker:29092
```