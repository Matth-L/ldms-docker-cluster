## 📁 LDMS Configuration (`ldms_conf`)

Contains all configuration files to deploy and manage the LDMS Sampler/Aggregator using Slurm's Prolog & Epilog.

```
.
├── agg.conf
├── agg_kafka.conf
├── decomp.json
├── epilog.d
│   └── stop_ldms.sh
├── prolog.d
│   └── launch_sampler.sh
├── README.md
├── sampler.conf
└── slurm-sampler.conf
```

### 📋 File and Directory Roles

  * **`agg_kafka.conf`**: **Production Aggregator Config.** Defines the central metric listener (Aggregator) that runs on the Slurm controller (`slurmctld`). It is configured to receive all metrics and stream them to the **Kafka broker**.
  * **`slurm-sampler.conf`**: Used by the Prolog script on compute nodes. Collect (`vmstat`, `meminfo`, etc.), using **Slurm job variables** for metric tagging.
  * **`decomp.json`**: Defines the JSON schema and necessary indexing (e.g., `timestamp`, `component_id`) required for Kafka .
  * **`prolog.d/launch_sampler.sh`:  Executed before a job starts. Launches the LDMS Sampler daemon (`ldmsd`).
  * **`epilog.d/stop_ldms.sh`**: Executed after a job finishes. Reads the PID and terminates the Sampler daemon.
  * **`agg.conf`** / **`sampler.conf`**: **Testing Files.** Rely on generic `HOSTNAME`; stores data to **CSV files**. __They do not use Slurm variables or Kafka__.