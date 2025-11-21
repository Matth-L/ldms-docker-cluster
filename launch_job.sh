#!/bin/bash

echo "Lancement avec userA"
docker exec -u userA:userA slurmctld bash -c "srun --mpi=pmix -N 1  ./data/sleep.sh" &

echo "Lancement avec userB"
docker exec -u userB:userB slurmctld bash -c "srun --mpi=pmix -N 1 ./data/sleep.sh" &

echo "Lancement avec userC"
docker exec -u userC:userC slurmctld bash -c "srun --mpi=pmix -N 1 ./data/sleep.sh" &

echo "Fin des lancements, ils tournent en arrière plan"

