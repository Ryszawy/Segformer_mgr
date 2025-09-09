FROM pytorch/pytorch:2.3.1-cuda11.8-cudnn8-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# System deps + toolchain + SSH (opcjonalnie)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git git-lfs wget curl ca-certificates unzip locales \
    build-essential cmake pkg-config \
    libgl1 libglib2.0-0 ffmpeg openssh-server \
 && rm -rf /var/lib/apt/lists/* \
 && sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen \
 && mkdir -p /var/run/sshd \
 && git lfs install

# Python bazowe
RUN pip install --no-cache-dir -U pip setuptools wheel

# Wymuszenie dokładnej wersji torch stack (zgodnie z Twoim środowiskiem)
# (obraz startowy ma już torch 2.3.1, ale pinujemy jawnie i dopasowujemy cu118)
RUN pip install --no-cache-dir \
    torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 \
    --index-url https://download.pytorch.org/whl/cu118

# MMEngine + MMCV dopasowane do Torch 2.3 + CUDA 11.8
# (sprawdzone kombo: mmengine < 0.11 oraz mmcv==2.2.0 pod cu118/torch2.3)
RUN pip install --no-cache-dir "mmengine<0.11"
RUN pip install --no-cache-dir "mmcv==2.2.0" \
    -f https://download.openmmlab.com/mmcv/dist/cu118/torch2.3/index.html

# MMSegmentation z gita (repo trzymamy w obrazie, na wolumen skopiujemy przy starcie)
RUN git clone -b main https://github.com/open-mmlab/mmsegmentation.git /opt/mmseg

# Instalacja editable (tymczasowo wskazuje /opt/mmseg; start.sh przepnie na /workspace)
RUN pip install --no-cache-dir -v -e /opt/mmseg

# Runtime i optional (pełny zestaw z requirements/)
RUN pip install --no-cache-dir -r /opt/mmseg/requirements/runtime.txt
# optional potrafi być ciężki, ale jeśli chcesz zgodność 1:1 z Twoim conda env, to dodajemy:
RUN pip install --no-cache-dir -r /opt/mmseg/requirements/optional.txt

# Runtime + narzędzia
RUN pip install --no-cache-dir \
    opencv-python-headless matplotlib pycocotools tqdm rich \
    openmim jupyterlab tensorboard

# Skrypt startowy + katalog roboczy
WORKDIR /workspace
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Porty: Jupyter + TensorBoard
EXPOSE 8888 6006
CMD ["/usr/local/bin/start.sh"]

