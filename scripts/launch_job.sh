#!/bin/bash
# This script launches one job per user, with each job in /shared/compute/sleep.sh
# Mapping: userA -> project1, userB -> project2, userC -> project3

set -euo pipefail
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

CONTAINER="slurmctld"
SCRIPT_PATH="/shared/compute/sleep.sh"
WALLTIME="00:12:00"

log "Launching jobs"

# Launch job for userA
log "Launching job as usera for project1..."
docker exec -u "usera:usera" "$CONTAINER" \
    srun --account=project1 --mpi=pmix -N 1 --time="$WALLTIME" "$SCRIPT_PATH" &

# Launch job for userB
log "Launching job as userb for project2..."
docker exec -u "userb:userb" "$CONTAINER" \
    srun --account=project2 --mpi=pmix -N 1 --time="$WALLTIME" "$SCRIPT_PATH" &

# Launch job for userC
log "Launching job as userc for project3..."
docker exec -u "userc:userc" "$CONTAINER" \
    srun --account=project3 --mpi=pmix -N 1 --time="$WALLTIME" "$SCRIPT_PATH" &

log "All jobs launched."