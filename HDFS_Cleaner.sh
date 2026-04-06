#!/bin/bash
# NEURAL-INFERENCE ENGINE: SYSTEM MAINTENANCE & CACHE PURGE

echo "[MAINTENANCE] Searching for stale Inference Output..."
hadoop fs -ls /Neural-Inference-Engine/Inference_Output

echo "[MAINTENANCE] Removing cached data cycles..."
hadoop fs -rm -r /Neural-Inference-Engine/Inference_Output/*

echo "[MAINTENANCE] Resetting Raw Ingress Buffer..."
hadoop fs -rm -r /Neural-Inference-Engine/Raw_Ingress/*

echo "[SUCCESS] System cleared. Ready for new Neural-Inference Cycle."
