#!/bin/bash
# Register the cluster to the slurm db
# Author : Matthias LAPU (CEA)

set -e

docker exec slurmctld bash -c "/usr/bin/sacctmgr --immediate add cluster name=linux" && \

docker compose restart slurmdbd slurmctld