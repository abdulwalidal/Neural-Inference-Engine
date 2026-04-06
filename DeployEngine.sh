#!/bin/bash


PROJECT_NAME="Neural-Inference-Engine"
INPUT_DIR="/Neural-Inference-Engine/Raw_Ingress"
OUTPUT_DIR="/Neural-Inference-Engine/Inference_Output/Cycle_$(date +%Y%m%d_%H%M)"

echo "----------------------------------------------------------------"
echo " [SYSTEM] INITIALIZING $PROJECT_NAME ARCHITECTURE "
echo "----------------------------------------------------------------"

# 1. NODE DIAGNOSTICS LAYER
echo "[STEP 1/4] Performing Cluster Health Check..."
NODE_COUNT=$(jps | grep -E 'NameNode|DataNode|SecondaryNameNode' | wc -l)

if [ "$NODE_COUNT" -lt 3 ]; then
    echo "[ALERT] Cluster Nodes Offline. Initiating Master/Slave boot sequence..."
    $HADOOP_HOME/sbin/start-dfs.sh
    sleep 5
else
    echo "[SUCCESS] All $NODE_COUNT Distributed Nodes are Synchronized."
fi

# 2. DATA INGRESS LAYER (HDFS)
echo "[STEP 2/4] Initializing HDFS Data Ingress..."
hadoop fs -mkdir -p $INPUT_DIR
hadoop fs -put -f records.txt $INPUT_DIR/
echo "[SUCCESS] Linguistic records injected into Ingress Layer."

# 3. COMPUTATION LAYER (MAPREDUCE)
echo "[STEP 3/4] Executing Parallel Inference Cycle..."
echo "[INFO] Mapping data fragments across virtualized nodes..."

hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar wordcount $INPUT_DIR $OUTPUT_DIR

# 4. POST-PROCESS VALIDATION
if [ $? -eq 0 ]; then
    echo "----------------------------------------------------------------"
    echo " [SUCCESS] NEURAL-INFERENCE CYCLE COMPLETED SUCCESSFULLY "
    echo "----------------------------------------------------------------"
    echo "[REPORT] Accessing Top-5 Inference Results:"
    hadoop fs -cat $OUTPUT_DIR/part-r-00000 | head -n 5
else
    echo "[ERROR] Inference Cycle Failure. Check HDFS Logs for details."
    exit 1
fi

echo "[STATUS] Orchestrator shutting down. Grid remains active."
