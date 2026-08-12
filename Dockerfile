# ============================================================
# ETAPA 1
# RunPod ComfyUI - Base + ComfyUI v0.26.2 + Torch CUDA 13
# ============================================================

FROM runpod/worker-comfyui:5.8.4-base

SHELL ["/bin/bash", "-c"]

# ============================================================
# 1. Fixar ComfyUI na versão que funcionou no Pod
#
# ComfyUI:
#   v0.26.2
#   commit 7ffd7983e72de29d90431fc746db9b41a4299d5e
# ============================================================

RUN cd /comfyui && \
    git fetch --tags origin && \
    git checkout v0.26.2

# ============================================================
# 2. Torch + CUDA 13.0
#
# Ambiente validado no Pod:
#   torch       2.10.0+cu130
#   torchvision 0.25.0+cu130
#   torchaudio  2.10.0+cu130
# ============================================================

RUN pip install --no-cache-dir --force-reinstall \
    torch==2.10.0 \
    torchaudio==2.10.0 \
    torchvision==0.25.0 \
    --index-url https://download.pytorch.org/whl/cu130

# ============================================================
# 3. Verificação do ambiente
# ============================================================

RUN echo "============================================" && \
    echo "COMFYUI" && \
    git -C /comfyui rev-parse HEAD && \
    git -C /comfyui describe --tags --always && \
    echo "============================================" && \
    echo "PYTHON" && \
    python3.12 --version && \
    echo "============================================" && \
    echo "TORCH / CUDA" && \
    python3.12 -c "import torch; print('Torch:', torch.__version__); print('CUDA:', torch.version.cuda); print('CUDA available:', torch.cuda.is_available())" && \
    echo "============================================"

WORKDIR /comfyui
