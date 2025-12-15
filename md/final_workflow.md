Back to the main README.md : [here](../README.md)


# Step 0

If not done already, launch the project and register the cluster.
```sh
docker compose up -d
./scripts/register_cluster.sh
```


# Step 1 : Launching the aggregator on `slurmctld`

First, we'll need to launch the aggregator. To do so, connect to `slurmctld`.
```sh
docker exec -it slurmctld bash
```

Load the library and launch the aggregator :
```sh
OVIS=/opt/ovis
export LD_LIBRARY_PATH=$OVIS/lib:$LD_LIBRARY_PATH
export LDMSD_PLUGIN_LIBPATH=$OVIS/lib/ovis-ldms
export ZAP_LIBPATH=$OVIS/lib/ovis-ldms
export PATH=$OVIS/sbin:$OVIS/bin:$PATH
export PYTHONPATH=$OVIS/lib/python3.9/site-packages

ldmsd -x sock:20001 -c /ldms_conf/agg_kafka.conf -l /tmp/log_agg.txt &
```
The aggregator will be available on socket 20001 and will listen to sampler using the socket 10001.
To check if the aggregator is up, run :
```sh
ldms_ls -h ${HOSTNAME} -x sock -p 20001 -v
# Ctrl+D
```

No query are received, which is normal because there isnt any job running on the slurm cluster yet.

# Step 2 : Init opensearch with the install demo

```sh
docker exec -it opensearch-node1 bash
sh plugins/opensearch-security/tools/install_demo_configuration.sh
#  -> press Yes [y] to all
# Ctrl-D
```

To check if the node is up , run the following command :

```sh
curl -k -XGET -u admin:SecureP@ssword1 https://localhost:9200
```

If this commands fails, wait a bit then retry. It should give something like this :

```json
{
  "name" : "opensearch-node1",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "XXXXX",
  "version" : {
    "distribution" : "opensearch",
    ...
  },
  "tagline" : "The OpenSearch Project: https://opensearch.org/"
}

```


# Step 3 : Launch job


```sh
./scripts/create_user.sh
./scripts/launch_job.sh
```

The following scripts will launch the `sleep.sh` script for three different users, associating each execution with a unique project name:

| User | Project Name | Script Executed |
| :--- | :--- | :--- |
| `userA` | `project1` | `sleep.sh` |
| `userB` | `project2` | `sleep.sh` |
| `userC` | `project3` | `sleep.sh` |


# STEP 4: Visualisation (Grafana Configuration)

This step involves verifying that the metrics have been indexed in OpenSearch and configuring the Grafana dashboard to display user-specific metrics using transformations.

## 4.1 Index Verification & Grafana Access

1. confirm the OpenSearch index has been created

**Verify Index Name:**

```sh
curl -k -XGET -u admin:SecureP@ssword1 https://localhost:9200/_cat/indices?v
```

**Access Grafana:**

Open : http://localhost:3000/

| Credential | Value |
| :--- | :--- |
| **User** | `admin` |
| **Password** | `SecureGrafanaPassword1` |

-----

## 4.2 OpenSearch Data Source Setup

Configure a new OpenSearch data source in Grafana using the following settings:

| Setting | Value | Configuration Detail |
| :--- | :--- | :--- |
| **URL** | `https://opensearch-node1:9200` | Address of the OpenSearch service. |
| **Auth** | Basic Auth | Use basic authentication. |
| **Skip TLS Verify** | Checked | Ignore TLS certificate errors  |
| **User** | `admin` | OpenSearch Security username. |
| **Password** | `SecureP@ssword1` | OpenSearch Security password. |
| **Index Name** | `ldms-metrics-*` | Target index for LDMS metrics. |

-----

## 4.3 Panel Query & Transformations (Job <-> user aggregation + Filter)

> The query A is a template to be used with query B to get any metrics from LDMS.

### Query A: Metric Retrieval

| Setting | Value |
| :--- | :--- |
| **Query Label** | `A` |
| **Query Type** | `Lucene` |
| **Metric** | `average, <metric_name>` (e.g., `average, load5min`) |
| **Group By** | `terms, component_id` |

### Query B: Component <-> user


| Setting | Value |
| :--- | :--- |
| **Query Label** | `B` |
| **Query Type** | `Lucene` |
| **Metric** | `count` |
| **Group By** | `terms, component_id` |
| **Then By** | `terms, username.keyword` |



### Transformations (Keep the same order)

Apply these steps in the **Transform** tab :

1.  **Join fields**

      * **Type:** `Inner`
      * **Field:** `component_id`
      * *Why ?:* Aggregates using `component_id`.

2.  **Filter data by values**

      * **Field:** `username.keyword`
      * **Condition:** `Is equal`
      * **Value:** `${__user.login}`
      * *Why ?:* Filters per username.

3.  **Organize fields by name**
      * Hide: `component_id`
      * Hide: `count`
      * *Why ?:* Removes useless data for visualization.

To test the filter :
1. Go to the profile picture at the top.
2. Change the username (e.g., set it to `usera`).