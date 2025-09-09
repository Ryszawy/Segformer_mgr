#!/usr/bin/env bash
set -e
# JupyterLab
mkdir -p /workspace/tmp /workspace/logs
export TMPDIR=/workspace/tmp
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
  --NotebookApp.token='' --NotebookApp.password='' \
  > /workspace/logs/jupyter.log 2>&1 &
# TensorBoard (logs + /workspace/logs and work_dirs)
tensorboard --logdir /workspace/logs:/workspace/code/mmsegmentation/work_dirs \
  --host 0.0.0.0 --port 6006 > /workspace/logs/tensorboard.log 2>&1 &

tail -f /dev/null

