#!/bin/bash
# Neural-Inference Engine: Automated Deployment Protocol

echo "[STATUS] Initializing HDFS Distributed Nodes..."
$HADOOP_HOME/sbin/start-dfs.sh

echo "[STATUS] Injecting Raw Linguistic Records into HDFS..."
hadoop fs -mkdir -p /Neural-Inference-Engine/Raw_Ingress
hadoop fs -put records.txt /Neural-Inference-Engine/Raw_Ingress/

echo "[STATUS] Executing Distributed Inference Cycle..."

hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar wordcount /Neural-Inference-Engine/Raw_Ingress /Neural-Inference-Engine/Inference_Output/Auto_Process

echo "[SUCCESS] Neural-Inference Cycle Complete."
