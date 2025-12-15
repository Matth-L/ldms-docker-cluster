#!/bin/bash
set -euo pipefail

NODES=("slurmctld" "c1" "c2" "c3")
USERS=("usera" "userb" "userc")

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"; }

for node in "${NODES[@]}"; do
    for user in "${USERS[@]}"; do
        HOME_DIR="/home/$user"

        log "[$node] Creating user $user..."
        docker exec "$node" bash -c "id $user >/dev/null 2>&1 || useradd -m -d '$HOME_DIR' -s /bin/bash '$user'"

        log "[$node] Ensuring home directory exists..."
        docker exec "$node" bash -c "mkdir -p '$HOME_DIR'; chown -R '$user:$user' '$HOME_DIR'"
    done
done

# Add Slurm accounts 
log "Creating Slurm accounts..."
for user in "${USERS[@]}"; do
    docker exec slurmctld bash -c "sacctmgr add account $user --immediate || true"
    docker exec slurmctld bash -c "sacctmgr create user $user defaultaccount=$user adminlevel=none --immediate || true"
done

log "DONE: Linux + Slurm users created across all nodes."
