Back to the main README.md : [here](../README.md)

## LDMS automatic sampler launch with slurm-user as name

### 1\. Launch job

```sh
# Inside slurmctld container

srun --mpi=pmix -N 3 sleep 200 &
squeue
```

### 2\. Compute node

```sh
# Inside compute node

OVIS=/opt/ovis
export LD_LIBRARY_PATH=$OVIS/lib:$LD_LIBRARY_PATH
export LDMSD_PLUGIN_LIBPATH=$OVIS/lib/ovis-ldms
export ZAP_LIBPATH=$OVIS/lib/ovis-ldms
export PATH=$OVIS/sbin:$OVIS/bin:$PATH
export PYTHONPATH=$OVIS/lib/python3.9/site-packages

ldms_ls -h ${HOSTNAME} -x sock -p 10001 -v

```

A script runs on compute nodes when a job starts. It launches an LDMS sampler, ensures detachment, and records the PID.


### 3\. How does Prolog and Epilog work for LDMS?

The Slurm **Prolog** and **Epilog** scripts are the automation layer that ensures an LDMS sampler runs only when a job is active on a node and cleans up after it.


#### A. Prolog Script: Sampler Launch (`/etc/slurm/prolog.sh`)

The Prolog script is executed on every compute node *before* the job step begins. Located [here](../ldms_conf/prolog.d/launch_sampler.sh)

#### B. Epilog Script: Sampler Cleanup (`/etc/slurm/epilog.sh`)

The Epilog script is executed on every compute node *after* the job completes or is canceled. Its job is to ensure that the Sampler daemon launched by the Prolog is correctly shut down and system resources (like the open socket port) are released.  Located [here](../ldms_conf/epilog.d/stop_ldms.sh)
