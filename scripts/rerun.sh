#/bin/bash
# This script aims to call most of the other scripts located in /scripts
# Creating a workflow that easily launches the cluster, with jobs for each user
# and LLView that gathers metrics
# Author : Matthias LAPU (CEA)

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}


log "Starting workflow..."

$BASEDIR/create_user.sh
$BASEDIR/launch_job.sh

log "Workflow lauched"