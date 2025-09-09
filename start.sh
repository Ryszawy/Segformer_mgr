#!/usr/bin/env bash
set -e

# Katalogi na wolumenie (trwałe)
mkdir -p /workspace/{code,data,ckpts,logs,tmp}
export TMPDIR=/workspace/tmp

# Jeżeli nie ma repo na wolumenie – skopiuj z obrazu i przepnij editable na wersję z /workspace
if [ ! -d /workspace/code/mmsegmentation/.git ]; then
  mkdir -p /workspace/code
  cp -r /opt/mmseg /workspace/code/mmsegmentation
  pip install -v -e /workspace/code/mmsegmentation
fi

# Auto-symlink na datasety (przykład: Cityscapes)
if [ -d /workspace/data/cityscapes ]; then
  mkdir -p /workspace/code/mmsegmentation/data
  if [ ! -e /workspace/code/mmsegmentation/data/cityscapes ]; then
    ln -sfn /workspace/data/cityscapes /workspace/code/mmsegmentation/data/cityscapes
  fi
fi

# Log wersji na starcie
python - <<'PY'
import torch, mmcv, mmengine
print("=== Runtime check ===")
print("Torch:", torch.__version__, "| CUDA runtime:", torch.version.cuda, "| CUDA available:", torch.cuda.is_available())
if torch.cuda.is_available():
    i=0
    print("Device:", torch.cuda.get_device_name(i), "| CC:", torch.cuda.get_device_capability(i))
print("MMCV:", mmcv.__version__, "| MMEngine:", mmengine.__version__)
PY

# JupyterLab (bez tokena)
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
  --NotebookApp.token='' --NotebookApp.password='' \
  > /workspace/logs/jupyter.log 2>&1 &

# TensorBoard
tensorboard --logdir /workspace/logs:/workspace/code/mmsegmentation/work_dirs \
  --host 0.0.0.0 --port 6006 \
  > /workspace/logs/tensorboard.log 2>&1 &

# (Opcjonalnie) SSH — włącz, jeśli podasz RUNPOD_SSH_PUBKEY w zmiennych środowiskowych
if [ -n "${RUNPOD_SSH_PUBKEY}" ]; then
  mkdir -p /root/.ssh
  echo "${RUNPOD_SSH_PUBKEY}" > /root/.ssh/authorized_keys
  chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config || true
  sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config || true
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config || true
  service ssh start || /usr/sbin/sshd
fi

# Utrzymaj kontener żywy na Runpod
tail -f /dev/null

