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


ldmsd -x sock:20001 -c /ldms_conf/agg_kafka.conf -l /tmp/log_agg.txt &

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

# Step 3 (PLUS d'actu) : Creating user, roles with the UI

You need to use the sampler `jobid` to get the user name in this proof of concept.

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

# STEP  GRAFANA ACTU MAIS PAS FINI A CORRIGER :


To get the index name of the ldms-metrics, supposed to be `ldms-metrics-*`, see [here](../logstash/pipeline/logstash.conf) :

```sh
curl -k -XGET -u admin:SecureP@ssword1 https://localhost:9200/_cat/indices?v
```

To connect to grafana : http://localhost:3000/

user : admin
password : SecureGrafanaPassword1

IN GRAFANA  :

url : https://opensearch-node1:9200

- auth : basic auth
- skip tls verify
- user : admin
- password : SecureP@ssword1

- index-name : ldms-metrics-*

## QUERY

> Explore
Query type : Lucene

A
metric, average, load5min
group by terms, component_id

B
metric, count
group by, terms, component_id
then_by terms username.keyword
---

Transformation

> Join by fied

Inner
field, component_id

>filter data by values
username.keyword is equal ${__user.login}

>Organize fields by name

hide component_id
hide count



https://grafana.com/docs/grafana/latest/visualizations/dashboards/variables/add-template-variables/#__user
org