# ldms-docker-cluster

This project is a fork of : https://github.com/giovtorres/slurm-docker-cluster.

It uses LDMS : https://ovis-hpc.readthedocs.io/projects/ldms/en/latest/index.html

The goal was to create a basic cluster, and install LDMS made to gather metrics in a HPC environment.

Made during my intership at CEA.

## Build

```sh
docker build -t slurm-docker-cluster --network=host -f docker/Dockerfile .
```

## Arborescence explanation

```

```

# Example :

- LDMS manual launch that gathers metrics and store them in `.csv` : [here](./md/ldms_csv.md)
- LDMS manual launch that gathers metrics and launch them in Kafka : [here](./md/ldms_kafka.md)