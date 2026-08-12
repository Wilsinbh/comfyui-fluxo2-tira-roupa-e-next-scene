# ============================================================
# ETAPA 3A
# ComfyUI + Torch CUDA 13
# + Custom Nodes
# + Qwen Rapid AIO
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
# 7. Hugging Face + hf-xet
# ============================================================

RUN pip install --no-cache-dir \
    "huggingface_hub[hf_xet]"

# ============================================================
# 8. Configuração de download
# ============================================================

ENV HF_XET_HIGH_PERFORMANCE=1
ENV HF_XET_NUM_CONCURRENT_RANGE_GETS=64
ENV HF_HUB_DOWNLOAD_TIMEOUT=300
ENV HF_HUB_ETAG_TIMEOUT=60
ENV HF_HUB_DISABLE_UPDATE_CHECK=1

# ============================================================
# 9. Diretório do modelo
# ============================================================

RUN mkdir -p /comfyui/models/checkpoints

# ============================================================
# 10. VERIFICAR SECRET
#
# O RunPod deve fornecer:
#
# HF_TOKEN={{ RUNPOD_SECRET_HF_TOKEN }}
# ============================================================

RUN echo "============================================" && \
    echo "TESTANDO HUGGING FACE TOKEN" && \
    if [ -z "$HF_TOKEN" ]; then \
        echo "ERRO: HF_TOKEN não foi disponibilizado pelo RunPod." >&2; \
        exit 1; \
    else \
        echo "HF_TOKEN recebido pelo build."; \
    fi && \
    echo "============================================"

# ============================================================
# 11. Download Qwen Rapid AIO
# ============================================================

RUN hf download \
    Phr00t/Qwen-Image-Edit-Rapid-AIO \
    Qwen-Rapid-AIO-NSFW-v11.4.safetensors \
    --revision main \
    --local-dir /comfyui/models/checkpoints \
    --token "$HF_TOKEN"

# ============================================================
# 12. Verificação
# ============================================================

RUN echo "============================================" && \
    echo "QWEN RAPID AIO INSTALADO" && \
    ls -lh /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors && \
    echo "============================================"

# ============================================================
# 13. Verificação ComfyUI / Torch
# ============================================================

RUN echo "===== COMFYUI =====" && \
    git -C /comfyui rev-parse HEAD && \
    git -C /comfyui describe --tags --always && \
    echo "===== PYTHON =====" && \
    python3.12 --version && \
    echo "===== TORCH / CUDA =====" && \
    python3.12 -c "import torch; print('Torch:', torch.__version__); print('CUDA:', torch.version.cuda); print('CUDA available:', torch.cuda.is_available())" && \
    echo "===== CUSTOM NODES =====" && \
    test -d /comfyui/custom_nodes/ComfyUI-Image-Saver && \
    test -d /comfyui/custom_nodes/RES4LYF && \
    test -d /comfyui/custom_nodes/rgthree-comfy && \
    test -d /comfyui/custom_nodes/ComfyUI-KJNodes && \
    echo "Custom Nodes: OK"

WORKDIR /comfyui
