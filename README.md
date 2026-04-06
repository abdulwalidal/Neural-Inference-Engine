# Neural-Inference-Engine

A distributed text-processing system built on **Apache Hadoop MapReduce** that performs parallel word-frequency analysis across an HDFS cluster. The pipeline is fully automated — from cluster health diagnostics to data ingestion, computation, and reporting.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Setup & Usage](#setup--usage)
- [Sample Data & Output](#sample-data--output)
- [Maintenance](#maintenance)
- [Component Reference](#component-reference)

---

## Overview

Neural-Inference-Engine orchestrates a four-stage MapReduce pipeline:

| Stage | Name | Description |
|-------|------|-------------|
| 1 | **Node Diagnostics** | Checks cluster health; auto-starts HDFS if needed |
| 2 | **Data Ingress** | Uploads raw text records into HDFS |
| 3 | **Computation** | Runs the distributed word-count MapReduce job |
| 4 | **Post-Process Validation** | Verifies completion and surfaces top results |

---

## Architecture

```
                      ORCHESTRATION LAYER
                        (DeployEngine.sh)
                                │
          ┌─────────────────────┼──────────────────────┐
          │                     │                      │
          ▼                     ▼                      ▼
    ┌───────────┐       ┌──────────────┐      ┌────────────────┐
    │  Cluster  │       │  HDFS Layer  │      │   MapReduce    │
    │  Health   │       │ (core-site / │      │   Job Config   │
    │  Check    │       │  hdfs-site)  │      └────────────────┘
    └───────────┘       └──────┬───────┘
                               │
                   ┌───────────▼───────────┐
                   │   Raw_Ingress (HDFS)  │  ← records.txt
                   └───────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                                 ▼
        ┌───────────┐                  ┌─────────────────────┐
        │  Mapper   │                  │ InferenceProcessor  │
        │ (Tokenize │                  │   NeuralMapper      │
        │  words)   │                  │   NeuralReducer     │
        └─────┬─────┘                  └─────────────────────┘
              │
        ┌─────▼──────┐
        │  Combiner  │  (local aggregation per node)
        └─────┬──────┘
              │
        ┌─────▼──────┐
        │  Reducer   │  (global aggregation)
        └─────┬──────┘
              │
   ┌──────────▼───────────┐
   │  Inference_Output    │  → part-r-00000 / final_inference_report.txt
   └──────────────────────┘

   ┌──────────────────────────────┐
   │   Maintenance Layer          │
   │   (HDFS_Cleaner.sh)         │
   │   · Purge stale cycles      │
   │   · Reset ingress buffer    │
   └──────────────────────────────┘
```

**Data flow:**

1. `records.txt` is uploaded to HDFS under `/Neural-Inference-Engine/Raw_Ingress`
2. **NeuralMapper** tokenises each line and emits `(word, 1)` pairs
3. **Combiner** performs local aggregation on each DataNode
4. **NeuralReducer** globally sums counts for every unique word
5. Results land in a timestamped output directory (`Inference_Output/Cycle_<timestamp>`)

---

## Project Structure

```
Neural-Inference-Engine/
├── InferenceProcessor.java      # MapReduce job (Mapper + Reducer + driver)
├── DeployEngine.sh              # End-to-end pipeline orchestration
├── HDFS_Cleaner.sh              # Maintenance: purge stale HDFS output
├── core-site.xml                # Hadoop core config (NameNode address)
├── hdfs-site.xml                # HDFS config (replication, data dirs)
├── records.txt                  # Sample input data
└── final_inference_report.txt   # Example output from a previous run
```

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| Java (JDK)  | 8 or later |
| Apache Hadoop | 3.4.1 (scripts reference this version) |
| Bash | Any modern version |

Hadoop must be installed at `/usr/local/hadoop` (the default path expected by the scripts). Adjust `HADOOP_HOME` in `DeployEngine.sh` if your installation differs.

---

## Configuration

### `core-site.xml`

```xml
<property>
    <name>fs.defaultFS</name>
    <value>hdfs://127.0.0.1:9000</value>
</property>
```

Points to the HDFS NameNode on localhost port 9000. Change the host/port for a multi-node cluster.

### `hdfs-site.xml`

| Property | Value | Notes |
|----------|-------|-------|
| `dfs.replication` | `1` | Increase to `3` for production clusters |
| `dfs.namenode.name.dir` | `/usr/local/hadoop/data/namenode` | NameNode metadata path |
| `dfs.datanode.data.dir` | `/usr/local/hadoop/data/datanode` | DataNode block storage path |

Copy both XML files to `$HADOOP_HOME/etc/hadoop/` before starting the cluster.

---

## Setup & Usage

### 1. Copy configuration files

```bash
cp core-site.xml hdfs-site.xml /usr/local/hadoop/etc/hadoop/
```

### 2. (Optional) Compile the custom MapReduce job

The default pipeline uses Hadoop's built-in `wordcount` example. To use `InferenceProcessor.java` instead:

```bash
# Compile
javac -cp /usr/local/hadoop/share/hadoop/common/*:/usr/local/hadoop/share/hadoop/mapreduce/* \
    InferenceProcessor.java

# Package
jar cvf InferenceProcessor.jar *.class
```

Then update `DeployEngine.sh` to point to `InferenceProcessor.jar` instead of the built-in examples JAR.

### 3. Run the full pipeline

```bash
bash DeployEngine.sh
```

The script will:
- Verify that NameNode, DataNode, and SecondaryNameNode are running (and start them if not)
- Create the HDFS input directory and upload `records.txt`
- Execute the MapReduce word-count job
- Print the top-5 inference results on success

### 4. Manual step-by-step execution

```bash
# Start HDFS
$HADOOP_HOME/sbin/start-dfs.sh

# Create input directory and upload data
hadoop fs -mkdir -p /Neural-Inference-Engine/Raw_Ingress
hadoop fs -put records.txt /Neural-Inference-Engine/Raw_Ingress/

# Run the job
hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar \
    wordcount \
    /Neural-Inference-Engine/Raw_Ingress \
    /Neural-Inference-Engine/Inference_Output/Cycle_$(date +%Y%m%d_%H%M)

# View results
hadoop fs -cat /Neural-Inference-Engine/Inference_Output/Cycle_*/part-r-00000
```

---

## Sample Data & Output

**Input (`records.txt`):**
```
Neural-Inference is the core of this engine.
Hadoop manages the distributed nodes.
Java is the language of the engine.
Neural-Inference provides the final results.
```

**Output (`final_inference_report.txt`):**
```
Hadoop              1
Java                1
Neural-Inference    2
core                1
distributed         1
engine.             2
final               1
is                  2
language            1
manages             1
nodes.              1
of                  2
provides            1
results.            1
the                 5
this                1
```

---

## Maintenance

Use `HDFS_Cleaner.sh` to reset the system between inference cycles:

```bash
bash HDFS_Cleaner.sh
```

This script:
- Lists all existing `Inference_Output` directories
- Removes stale output cycles from HDFS
- Purges the `Raw_Ingress` buffer

Run this before re-uploading new input data to avoid HDFS output-directory conflicts.

---

## Component Reference

### `InferenceProcessor.java`

| Class | Role |
|-------|------|
| `NeuralMapper` | Extends `Mapper<Object, Text, Text, IntWritable>` — tokenises input lines and emits `(word, 1)` |
| `NeuralReducer` | Extends `Reducer<Text, IntWritable, Text, IntWritable>` — sums all counts per word |
| `main()` | Configures and submits the Hadoop job; sets Mapper, Combiner, and Reducer classes |

### `DeployEngine.sh`

| Variable | Default | Description |
|----------|---------|-------------|
| `HADOOP_HOME` | `/usr/local/hadoop` | Hadoop installation directory |
| `INPUT_DIR` | `/Neural-Inference-Engine/Raw_Ingress` | HDFS input path |
| `OUTPUT_DIR` | `/Neural-Inference-Engine/Inference_Output/Cycle_<timestamp>` | HDFS output path |

### `HDFS_Cleaner.sh`

Standalone maintenance script. No required arguments. Purges all inference output and ingress data from HDFS.
