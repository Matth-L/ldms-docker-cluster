# Scripts

Multiple scripts are used to make this project more simple to launch :

- create_user.sh: Creates multiple users and registers them with the SLURM cluster.
- launch_job.sh: Submits a simple job for each user. This job is located in shared/compute/.
- register_cluster.sh: Registers the cluster with the SLURM database (slurmdbd).
> Note: This script should only be run once when the project is first set up.