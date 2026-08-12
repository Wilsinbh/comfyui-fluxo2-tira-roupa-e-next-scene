# ============================================================
# ETAPA 3A
# ComfyUI + Torch CUDA 13
# + Custom Nodes
# + Qwen Rapid AIO
#
# Download otimizado via Hugging Face + hf-xet
#
# IMPORTANTE:
# HF_TOKEN deve estar configurado no RunPod como Secret
# com a chave:
#
# HF_TOKEN
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
# 7. Hugging Face + Xet
#
# hf-xet é o mecanismo moderno de transferência do Hugging Face.
# ============================================================

RUN pip install --no-cache-dir \
    "huggingface_hub[hf_xet]"

# ============================================================
# 8. Configuração de download de alta performance
# ============================================================

ENV HF_XET_HIGH_PERFORMANCE=1
ENV HF_XET_NUM_CONCURRENT_RANGE_GETS=64
ENV HF_HUB_DOWNLOAD_TIMEOUT=300
ENV HF_HUB_ETAG_TIMEOUT=60
ENV HF_HUB_DISABLE_UPDATE_CHECK=1

# ============================================================
# 9. Diretório do checkpoint
# ============================================================

RUN mkdir -p /comfyui/models/checkpoints

# ============================================================
# 10. Download Qwen Rapid AIO
#
# O HF_TOKEN vem do Secret configurado no RunPod.
#
# NÃO colocar o token no Dockerfile.
# ============================================================

RUN test -n "$HF_TOKEN" || \
    (echo "ERRO: HF_TOKEN não está disponível durante o build." && exit 1)

RUN echo "============================================" && \
    echo "HUGGING FACE AUTHENTICATION" && \
    echo "============================================" && \
    hf auth whoami

# ============================================================
# Download
# ============================================================

RUN hf download \
    Phr00t/Qwen-Image-Edit-Rapid-AIO \
    Qwen-Rapid-AIO-NSFW-v11.4.safetensors \
    --revision main \
    --local-dir /comfyui/models/checkpoints \
    --token "$HF_TOKEN"

# ============================================================
# 11. Verificação do modelo
# ============================================================

RUN echo "============================================" && \
    echo "QWEN RAPID AIO" && \
    ls -lh /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors && \
    echo "============================================"

# ============================================================
# 12. Verificação final
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
    echo "============================================" && \
    echo "CUSTOM NODES" && \
    test -d /comfyui/custom_nodes/ComfyUI-Image-Saver && \
    test -d /comfyui/custom_nodes/RES4LYF && \
    test -d /comfyui/custom_nodes/rgthree-comfy && \
    test -d /comfyui/custom_nodes/ComfyUI-KJNodes && \
    echo "Custom Nodes: OK" && \
    echo "============================================" && \
    echo "MODEL" && \
    ls -lh /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors && \
    echo "============================================"

WORKDIR /comfyui
