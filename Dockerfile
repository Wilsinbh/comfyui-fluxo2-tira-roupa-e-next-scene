# ============================================================
# ETAPA 2
# RunPod ComfyUI + Custom Nodes
# ============================================================

FROM runpod/worker-comfyui:5.8.4-base

SHELL ["/bin/bash", "-c"]

# ============================================================
# 1. ComfyUI v0.26.2
# ============================================================

RUN cd /comfyui && \
    git fetch --tags origin && \
    git checkout v0.26.2

# ============================================================
# 2. Torch + CUDA 13.0
# ============================================================

RUN pip install --no-cache-dir --force-reinstall \
    torch==2.10.0 \
    torchaudio==2.10.0 \
    torchvision==0.25.0 \
    --index-url https://download.pytorch.org/whl/cu130

# ============================================================
# 3. ComfyUI Image Saver
# ============================================================

RUN git clone \
    https://github.com/alexopus/ComfyUI-Image-Saver.git \
    /comfyui/custom_nodes/ComfyUI-Image-Saver && \
    pip install --no-cache-dir \
    -r /comfyui/custom_nodes/ComfyUI-Image-Saver/requirements.txt

# ============================================================
# 4. RES4LYF
# ============================================================

RUN git clone \
    https://github.com/ClownsharkBatwing/RES4LYF.git \
    /comfyui/custom_nodes/RES4LYF && \
    pip install --no-cache-dir \
    -r /comfyui/custom_nodes/RES4LYF/requirements.txt

# ============================================================
# 5. rgthree-comfy
# ============================================================

RUN git clone \
    https://github.com/rgthree/rgthree-comfy.git \
    /comfyui/custom_nodes/rgthree-comfy

# ============================================================
# 6. ComfyUI-KJNodes
# ============================================================

RUN git clone \
    https://github.com/kijai/ComfyUI-KJNodes.git \
    /comfyui/custom_nodes/ComfyUI-KJNodes && \
    pip install --no-cache-dir \
    -r /comfyui/custom_nodes/ComfyUI-KJNodes/requirements.txt

# ============================================================
# 7. Verificação
# ============================================================

RUN echo "============================================" && \
    echo "COMFYUI" && \
    git -C /comfyui rev-parse HEAD && \
    git -C /comfyui describe --tags --always && \
    echo "============================================" && \
    echo "TORCH / CUDA" && \
    python3.12 -c "import torch; print('Torch:', torch.__version__); print('CUDA:', torch.version.cuda)" && \
    echo "============================================" && \
    echo "CUSTOM NODES" && \
    ls -la /comfyui/custom_nodes/ComfyUI-Image-Saver && \
    ls -la /comfyui/custom_nodes/RES4LYF && \
    ls -la /comfyui/custom_nodes/rgthree-comfy && \
    ls -la /comfyui/custom_nodes/ComfyUI-KJNodes && \
    echo "============================================"

WORKDIR /comfyui
