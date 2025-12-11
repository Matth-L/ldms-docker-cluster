Back to the main README.md : [here](../README.md)

# Step 1 (Preparation)

## Launch the aggregator on `slurmctld`


```sh
docker compose up -d
./scripts/register_cluster.sh

docker exec -it slurmctld bash
```

Then, you'll need to export LDMS libs and launch the aggregator :
```sh
OVIS=/opt/ovis
export LD_LIBRARY_PATH=$OVIS/lib:$LD_LIBRARY_PATH
export LDMSD_PLUGIN_LIBPATH=$OVIS/lib/ovis-ldms
export ZAP_LIBPATH=$OVIS/lib/ovis-ldms
export PATH=$OVIS/sbin:$OVIS/bin:$PATH
export PYTHONPATH=$OVIS/lib/python3.9/site-packages


ldmsd -x sock:20001 -c /ldms_conf/agg_kafka.conf &

# check if the daemon is up
ldms_ls -h ${HOSTNAME} -x sock -p 20001 -v
# Ctrl+D
```

## Init opensearch with the install demo

```sh
docker exec -it opensearch-node1 bash
sh plugins/opensearch-security/tools/install_demo_configuration.sh
#  -> press Yes [y] to all
# Ctrl-D
```
Something should appear now, if not, wait and then retry :

```sh
curl -k -XGET -u admin:SecureP@ssword1 https://localhost:9200
```

It should give something like this :

```
{
  "name" : "opensearch-node1",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "XXXXX",
  "version" : {
    "distribution" : "opensearch",
    "number" : "3.3.2",
    "build_type" : "tar",
    "build_hash" : "XXXXX",
    "build_date" : "XXXXX,
    "build_snapshot" : false,
    "lucene_version" : "10.3.1",
    "minimum_wire_compatibility_version" : "2.19.0",
    "minimum_index_compatibility_version" : "2.0.0"
  },
  "tagline" : "The OpenSearch Project: https://opensearch.org/"
}

```

# Step 2 : Launch job

It will launch : 
- user:userA ; project:project1  ; script:sleep.sh
- user:userB ; project:project2  ; script:sleep.sh
- user:userC ; project:project3  ; script:sleep.sh

```sh
./scripts/create_user.sh
./scripts/launch_job.sh
```

# Step 3 : Creating user, roles with the UI

you need to use `jobid` to get the user name.


Connect as an admin to opensearch dashboards, http://localhost:5601

- user : `admin`
- password : `SecureP@ssword1`

Add an index patern :

> Management > Dashboards Management > Index patterns.


Let's try for userA


Choose Security, Internal Users, and Create internal user.

- user : `userA`
- password : `SecureP@ssword1`

Choose Security, Roles, and Create role.

- name : `clusterUser`