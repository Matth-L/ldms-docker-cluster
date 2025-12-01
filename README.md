# Proof of concept : LDMS
This project is a fork of : https://github.com/giovtorres/slurm-docker-cluster.

It uses LDMS : https://ovis-hpc.readthedocs.io/projects/ldms/en/latest/index.html

The goal was to create a basic cluster, and install LDMS made to gather metrics in a HPC environment.

Made during my intership at CEA.

## Build

[See here for the docker install](./md/docker.md)

## Arborescence explanation

```
.
├── 📁 docker
├── docker-compose.yml
├── docker-entrypoint.sh
├── 📁 (md)
├── README.md
├── 📁 scripts
├── 📁 shared
|-------- 📁compute | 📁 data
└── 📁 slurm
```

- `docker` -> Dockerfile for the main image; named `slurm-docker-cluster`
- `md` -> all the file located below in the Example section are written here
- `scripts` -> shell script to create user [scripts explanation](./scripts/README.md)
- `shared` -> a shared folder for all the node. The compute folders is only mounted on the `compute` node, .ie `c1`, `c2`, `c3`. The folder `data` is mounted as is in the `slurmctld` service.

The mount is made using the docker compose `volume` method.

> All the subfolders contains README.md

## Example :

- LDMS manual launch that gathers metrics and store them in `.csv` : [here](./md/ldms_csv.md)
- LDMS manual launch that gathers metrics and launch them in Kafka : [here](./md/ldms_kafka.md)