#

## Build

```sh
docker compose up -d --build
```

```sh
docker build -t slurm-docker-cluster --network=host -f docker/Dockerfile .
```

## Arborescence explanation

```

```

# Example :

- LDMS manual launch that gathers metrics and store them in `.csv` : [here](./md/ldms_csv.md)
- LDMS manual launch that gathers metrics and launch them in Kafka : [here](./md/ldms_kafka.md)