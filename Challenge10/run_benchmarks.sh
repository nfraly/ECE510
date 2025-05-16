#!/bin/bash

echo "Running GPU benchmark..."
python3 q_learning_gpu_optimized.py >> benchmark_results.txt

echo "Running CPU benchmark..."
python3 q_learning_original.py >> benchmark_results.txt

echo "Benchmarking complete. Results saved in benchmark_results.txt."
