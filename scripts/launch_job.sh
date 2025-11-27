#!/bin/bash
# This script launches one job per user, the job is in :  /shared/compute/X
# for all the users according to the mapping below
# userA -> project1; userB -> project2; userC -> project3
# Author : Matthias LAPU (CEA)

set -euo pipefail

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

CONTAINER="slurmctld"
SCRIPT_PATH="./shared/compute/sleep.sh"
WALLTIME="00:12:00"

declare -A PROJECTS
PROJECTS=( ["userA"]="project1" ["userB"]="project2" ["userC"]="project3" )
USERS=("userA" "userB" "userC")

log "Launching jobs"

for user in "${USERS[@]}"; do
    account="${PROJECTS[$user]}"
    log "Launching interactive job as $user for $account..."
    docker exec -u "${user}:${user}" "$CONTAINER" bash -c \
    "srun \
        --account=$account \
        --mpi=pmix \
        -N 1 \
    --time=$WALLTIME $SCRIPT_PATH" &
done


log "All jobs launched."