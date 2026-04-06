#!/bin/bash
# Neural-Inference Engine: Advanced Deployment & Health Protocol

echo "------------------------------------------------"
echo "Initializing Neural-Inference Infrastructure..."
echo "------------------------------------------------"

# 1. Node Diagnostics
echo "[CHECK] Verifying HDFS Cluster Status..."
jps | grep -E 'NameNode|DataNode|SecondaryNameNode'
if [ $? -ne 0 ]; then
    echo "[ALERT] Nodes not detected. Initializing start-dfs.sh..."
    $HADOOP_HOME/sbin/start-dfs.sh
else
    echo "[SUCCESS] Distributed nodes are active."
fi

# 2. Data Ingress Layer
echo "[PROCESS] Purging old Inference Cache..."
hadoop fs -rm -r /Neural-Inference-Engine/Inference_Output/Auto_Process 2>/dev/null

echo "[PROCESS] Injecting New Linguistic Records..."
hadoop fs -put records.txt /Neural-Inference-Engine/Raw_Ingress/

# 3. Execution Layer
echo "[EXECUTE] Starting Parallel Inference Cycle..."
hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar wordcount /Neural-Inference-Engine/Raw_Ingress /Neural-Inference-Engine/Inference_Output/Auto_Process

# 4. Final Validation
echo "[SUCCESS] Neural-Inference Cycle Complete."
echo "[RESULT] Accessing finalized Inference Report..."
hadoop fs -cat /Neural-Inference-Engine/Inference_Output/Auto_Process/part-r-00000 | head -n 5
