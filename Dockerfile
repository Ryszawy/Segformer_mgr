FROM pytorch/pytorch:2.4.1-cuda12.1-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Narzędzia, biblioteki runtime + toolchain do budowania (C/C++), SSH (opcjonalnie)
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

# MMEngine + MMCV (dopasowane do Torch 2.4 + CUDA 12.1)
RUN pip install --no-cache-dir "mmengine<0.11"
RUN pip install --no-cache-dir "mmcv==2.2.0" -f https://download.openmmlab.com/mmcv/dist/cu121/torch2.4/index.html

# MMSegmentation **w obrazie**, poza /workspace (bo /workspace to volume)
RUN git clone https://github.com/open-mmlab/mmsegmentation.git /opt/mmseg

# Instalacja editable (na razie wskazuje /opt/mmseg; start.sh przepnie na /workspace)
RUN pip install --no-cache-dir -v -e /opt/mmseg

# Runtime + narzędzia użyteczne
RUN pip install --no-cache-dir -r /opt/mmseg/requirements/runtime.txt \
    opencv-python-headless matplotlib tqdm rich ftfy regex pycocotools \
    openmim jupyterlab tensorboard

# --- Optional: wymagają czasem kompilacji (tokenizers) ---

# Rust toolchain do budowania `tokenizers` (i innych paczek opartych o Rust)
# Minimalny profil, stable jako domyślny
#RUN curl https://sh.rustup.rs -sSf | bash -s -- -y --profile minimal && \
#    /root/.cargo/bin/rustup default stable
#ENV PATH="/root/.cargo/bin:${PATH}"
# Zainstaluj optional (teraz powinno przejść bez błędów tokenizerów)
#RUN pip install --no-cache-dir -r /opt/mmseg/requirements/optional.txt

# Skrypt startowy
WORKDIR /workspace
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Porty: Jupyter + TensorBoard
EXPOSE 8888 6006
CMD ["/usr/local/bin/start.sh"]

