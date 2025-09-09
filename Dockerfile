FROM pytorch/pytorch:2.4.1-cuda12.1-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget curl ca-certificates vim nano tmux htop unzip locales \
    libgl1 libglib2.0-0 ffmpeg \
 && rm -rf /var/lib/apt/lists/* \
 && sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen

WORKDIR /workspace
RUN mkdir -p /workspace/code /workspace/data /workspace/ckpts /workspace/logs

RUN pip install --no-cache-dir -U pip setuptools wheel
RUN pip install --no-cache-dir "mmengine<0.11"
RUN pip install --no-cache-dir "mmcv==2.2.0" -f https://download.openmmlab.com/mmcv/dist/cu121/torch2.4/index.html

RUN git clone https://github.com/open-mmlab/mmsegmentation.git /workspace/code/mmsegmentation
WORKDIR /workspace/code/mmsegmentation
RUN pip install --no-cache-dir -v -e .
RUN pip install --no-cache-dir -r requirements/runtime.txt \
    opencv-python-headless matplotlib tqdm rich ftfy regex pycocotools openmim jupyterlab tensorboard

WORKDIR /workspace
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8888 6006
CMD ["/usr/local/bin/start.sh"]

