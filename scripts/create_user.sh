#!/bin/bash
# This scipt creates slurm users and add them to the cluster using sacctmgr
# Author : Matthias LAPU (CEA)

set -euo pipefail

CONTAINER="slurmctld"
USERS=("userA" "userB" "userC")

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

for user in "${USERS[@]}"; do
    HOME_DIR="/home/$user"

    log "Creating user $user with home directory $HOME_DIR..."
    docker exec "$CONTAINER" bash -c "useradd -m '$user' -d '$HOME_DIR' \
    || echo 'User $user may already exist.'"

    log "Adding Slurm account for $user..."
    docker exec "$CONTAINER" bash -c "sacctmgr add account '$user' --immediate \
    || echo 'Account $user may already exist.'"

    log "Creating Slurm user $user with default account $user..."
    docker exec "$CONTAINER" bash -c \
    "sacctmgr create user '$user' \
    defaultaccount='$user' \
    adminlevel=none --immediate \
    || echo 'User $user may already exist in Slurm.'"
done

log "All users created and added to Slurm."