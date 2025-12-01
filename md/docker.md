# Slurm-docker-cluster

This is the main image used for this project. It uses the multi-stage build feature from docker.

There a 2 stages :
- the build one where all the packages are built from source, the version used for those packages are `ARG` at the top of the file.
- the runtime, where only the libs and binaries related to the `make install`of the build phase is copied. Additionnal copy related to slurm config, .ie `groupadd` and so on are also made.

An anchor is used for the compute node, even though the number of compute node is 3 for this whole project and config files were written to follow this logic. So further modification should be made to make this general.

# How to build 

```sh
docker build -t slurm-docker-cluster --network=host .
```