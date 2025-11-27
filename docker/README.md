
# Why ?
To reduce the size of the image and to gain time by using Docker cache, file like :
- `pdsh.Dockerfile`
- `pmix.Dockerfile`
- `slurm.Dockerfile`
uses multistage, they all have the first stage named build, where the git clone and the make install is made, then we use FROM base, and only copy the binary in /opt.

# How to build

```sh
docker build --network=host -t base -f docker/base.Dockerfile .
docker build --network=host -t pdsh -f docker/pdsh.Dockerfile .
docker build --network=host -t pmix -f docker/pmix.Dockerfile .
docker build --network=host -t slurm -f docker/slurm.Dockerfile .

```
PAS SUR QUE CHANGER EN OPT SOIT UNE BONNE IDÉE CAR PEUT ETRE QUE LDMS CHERCHE DANS USR LOCAL ET VA PAS PLUS LONI A VOIR