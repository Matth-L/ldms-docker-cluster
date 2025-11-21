# POC : Docker slurm openMPI, avec LDMS
## Matthias Lapu 

Ce projet est un cluster (sous docker) avec slurm avec openmpi et pmix d'installé. Ce cluster est fonctionnel et la communication entre les noeuds fonctionne. 

- Il y a 3 noeuds (`c1`,`c2`,`c3`). 

Le noeud de login est `slurmctld`. Lorsqu'un job est lancé, un daemon LDMS est lancé sur le noeud de calcul qui correspond, lorsque le job se termine, le daemon LDMS s'arrête. Les métriques sont récupérés et stocké en tant que `.csv`, il est également possible de faire cela avec Kafka, et ça fonctionne. 

# TLDR des commandes:

```sh 
source .env
cd ldms
docker build --network=host -t ldms-agg-kafka .
cd ..
docker build --network=host -t slurm-docker-cluster .
docker compose up -d
./register_cluster.sh

# attendre quelque secondes 
./create_user.sh
./launch_job.sh 
```
Puis il faut se connecter au noeud de login : 

```sh
docker exec -it slurmctld bash 
```

Charger l'image de l'agrégateur :
```sh
podman load -i /images/ldms-agg-kafka.tar
```

Puis, lancement de l'agrégateur (agg.conf -> stockage en .csv, agg_kafka.conf -> envoie à Kafka) : 
```sh
podman run --rm -d \
  --name=agg \
  --network=host \
  -v ./data/store:/data/store:rw \
  -v /run/munge:/run/munge:ro \
  -v /etc/munge/munge.key:/etc/munge/munge.key:ro \
  -v "/etc/slurm/scripts/agg.conf:/agg.conf:ro" \
  localhost/ldms-agg-kafka \
  -x sock:20001 \
  -c /agg.conf \
  -F
```
Si on se connecte dans le docker de l'aggrégateur (qui est déja dans le docker du noeud de login ).
Cette commande permet de vérifier que l'agrégateur fonctionne bien : 
```sh 
ldms_ls -h ${HOSTNAME} -x sock -p 20001 -v
```

Si les données sont stockés en `.csv`, elles seront récupérées ici : 

```sh
tail /data/store/store_csv/meminfo_store/meminfo
wc -l /data/store/store_csv/meminfo_store/meminfo
wc -l /data/store/store_csv/meminfo_store/meminfo
wc -l /data/store/store_csv/meminfo_store/meminfo
```

> En faisant `wc -l` plusieurs foit, on voit que les lignes augmentent. 

Dans la 3e colonne des .csv il y a `ProducerName`. C'est le nom du job slurm avec l'utilisateur qui l'a lancé et le noeud sur lequel il tourne, on peut avoir d'autre information comme le slurm_job_id, je ne l'ai pas mis pour les tests.


# 1 : Build le conteneur

Il faut construire l'image de l'agrégateur et le sauvegarder dans `/images` : 

```sh
podman build --network=host -t ldms-agg-kafka .
podman save -o ./images/ldms-agg-kafka.tar ldms-agg-kafka:latest
```

Cette image est l'image de l'agrégateur LDMS auquel des librairies kafka sont ajoutés.

Pour construire le conteneur-cluster : 

> Utiliser sudo si docker n'a pas les permissions
```sh 
# build
source .env

# /!\ l'image fait presque 2 go et le build est long
docker build --network=host -t slurm-docker-cluster .

docker compose up -d
```

Un cluster avec slurm et 3 noeuds de calcul est crées (les noeuds sont nommés c1,c2,c3). 
Pour vérifier cela, faire la commande : 

```sh 
docker ps -a
```

> Lors du premier lancement, il faut exécuté : 

```sh 
./register_cluster.sh
```

Cette commande permet d'enregistre le cluster dans slurm.

Il faut ensuite se connecter au noeud de login et lancé l'agrégateur : 

```sh
# connexion au noeu de login
docker exec -it slurmctld bash 
# on charge l'image de l'agrégateur
podman load -i /images/ldms-agg-kafka.tar
# on lance l'agrégateur
podman run --rm -d\
  --name=agg \
  --network=host \
  -v /run/munge:/run/munge:ro \
  -v /etc/munge/munge.key:/etc/munge/munge.key:ro \
  -v "/etc/slurm/scripts/agg_kafka.conf:/agg_kafka.conf:ro" \
  -v "/etc/slurm/scripts/decomp.json:/decomp.json:ro" \
  localhost/ldms-agg-kafka \
  -x sock:20001 \
  -c /agg_kafka.conf \
  -F
```

# 2 : Execution 

Le script ci-dessous va créer 3 utilisateurs sur le noeud de login et va les enregistrer dans slurm : 

```sh 
./create_user.sh
```

/!\ s'il y a marqué `connection refused` c'est que la commande a été lancé trop rapidement et que le conteneur n'a pas eu le temps de se lancer, il faut juste attendre quelques secondes et le relancer.


Les utilisateurs crées sont `userA`, `userB` et `userC`. Pour vérifier que les utilisateurs peuvent bien lancer des jobs : 
- userA -> lance sleep.sh sur 1 noeud
- userB -> lance sleep.sh sur 1 noeud
- userC -> lance sleep.sh sur 1 noeud

> Le script `sleep.sh` effectue la commande `sleep 1000`.

## Si l'agrégateur stock en `.csv`

Les fichiers sont stockés dans `shared_data/store/store_csv/`, ce dossier est monté dans l'aggrégateur.

Ensuite, pour les consulter, il faut se connecter au noeud de login, puis dans l'agrégateur en faisant la commande suivante : 

```sh 
docker exec -it slurmctld bash 
docker exec -it agg bash 

# vérifier la récupération des métriques
ldms_ls -h ${HOSTNAME} -x sock -p 20001 -v
```

--- 

-> On lance un agrégateur qui va écouter au port 10001 les daemons LDMS qui tourne sur les noeuds c1,c2,c3 (voir `/slurm/agg_prolog.conf`). Il va stocker les données .csv dans le volume montés. 

Un volume est monté sur le noeud de login `shared_data`. Il possède le script sleep lancé par les noeuds de calculs ainsi  que la ou les données seront stockés par l'aggrégateur.

## Sinon -> Kafka

C'est le même fonctionnement mais on envoie a kafka et on ne stock pas. 
Kafka est compris dans le docker compose, il est déjà bien configuré avec LDMS. Il suffit de se connecter a kafka et a consommer les métriques : 

```sh 
#connexion a kafka 
docker exec -it kafka bash

# lister les différents topics
/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server broker:29092

# remplacer <topic> par un topic montré plus haut
 /opt/kafka/bin/kafka-console-consumer.sh --topic <topic> --from-beginning --bootstrap-server broker:29092
```

## ATTENTION 

Les métriques ne seront récupérés que si l'agrégateur fonctionne et récupère bien les métriques depuis les différents noeuds, il faut donc lancer l'agrégateur, puis lancer le script avec les jobs, puis vérifier tous ça dans kafka ou alors dans le .csv. 

# Comment ça fonctionne la récupération des métriques ? 

A chaque lancement de job slurm (`srun`), un prolog va se lancer qui va posséder, en variable d'environnement :  le nom de l'utilisateur, le job_id slurm etc.
Le prolog sera lancé sur le noeud de calcul utilisé, et il va lancer mon script `launch_sampler.sh`. Ce script lance un sampler LDMS  sur la socket 10001.
L'aggrégateur lui tourne en continue sur le noeud de login et stocke les données récupérées par les noeuds de calculs.

Les différents jobs sont différenciés par le nom de leurs instances sur les noeuds de calculs. 

Retour de la commande `ldms_ls -h ${HOSTNAME} -x sock -p 20001 -v` : 

```
Schema         Instance                 Flags  Msize  Dsize  Hsize  UID    GID    Perm       Update            Duration          Info    
-------------- ------------------------ ------ ------ ------ ------ ------ ------ ---------- ----------------- ----------------- --------
vmstat         userC-c1/vmstat              R   10256   1592      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
procstat2      userC-c1/procstat2           R    1816   1704   1536      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
procinterrupts userC-c1/procinterrupts      R   24744   4544      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
meminfo        userC-c1/meminfo             R    3112    568      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
loadavg        userC-c1/loadavg             R     632    160      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
dstat          userC-c1/dstat               R    1976    376      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
vmstat         userB-c3/vmstat              R   10256   1592      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
procstat2      userB-c3/procstat2           R    1816   1704   1536      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
procinterrupts userB-c3/procinterrupts      R   24744   4544      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
meminfo        userB-c3/meminfo             R    3112    568      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
loadavg        userB-c3/loadavg             R     632    160      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
dstat          userB-c3/dstat               R    1976    376      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
vmstat         userA-c2/vmstat              R   10256   1592      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
procstat2      userA-c2/procstat2           R    1816   1704   1536      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
procinterrupts userA-c2/procinterrupts      R   24744   4544      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
meminfo        userA-c2/meminfo             R    3112    568      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
loadavg        userA-c2/loadavg             R     632    160      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
dstat          userA-c2/dstat               R    1976    376      0      0      0 -r--r-----          0.000000          0.000000 "updt_hint_us"="1000000:100000" 
-------------- ------------------------ ------ ------ ------ ------ ------ ------ ---------- ----------------- ----------------- --------
```

Ici, j'ai mis : `${SLURM_JOB_USER}-${SLURMD_NODENAME}` comme nom.

Dans le fichier `.csv` a la 3e colonne on peut bien retrouver ce nom. Problèmes, toutes les données sont stockés dans un seul fichier et non dans plusieurs mais on a une colonne avec le nom des utilisateurs.

J'ai essayé de créer un dossier par job utilisateur ça ne semblait pas fonctionner , je n'ai pas l'impression que LDMS permettent le fait de nommer un dossier par utilisateur. Cela force un "gros fichier" .csv à analyser, ou alors un stream de donnée qui mélange les utilisateurs, pas forcément dérangeant mais important à noter.