#!/bin/bash 

echo "Creating userA and adding to Slurm"
docker exec slurmctld bash -c "useradd -m 'userA' -d '/home/userA' "
docker exec slurmctld bash -c "sacctmgr add account 'userA' --immediate"
docker exec slurmctld bash -c "sacctmgr create user 'userA' defaultaccount='userA' adminlevel=[None] --immediate"

echo "Creating userB and adding to Slurm"
docker exec slurmctld bash -c "useradd -m 'userB' -d '/home/userB' "
docker exec slurmctld bash -c "sacctmgr add account 'userB' --immediate"
docker exec slurmctld bash -c "sacctmgr create user 'userB' defaultaccount='userB' adminlevel=[None] --immediate"

echo "Creating userC and adding to Slurm"
docker exec slurmctld bash -c "useradd -m 'userC' -d '/home/userB' "
docker exec slurmctld bash -c "sacctmgr add account 'userC' --immediate"
docker exec slurmctld bash -c "sacctmgr create user 'userC' defaultaccount='userC' adminlevel=[None] --immediate"
