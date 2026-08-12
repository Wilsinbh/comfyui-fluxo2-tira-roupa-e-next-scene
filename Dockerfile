# ============================================================
# ETAPA 3A
# ComfyUI + Torch CUDA 13
# + Custom Nodes
# + Qwen Rapid AIO
#
# O modelo é público no Hugging Face.
# Não depende de HF_TOKEN.
#
# O BuildKit/RunPod deve reaproveitar as etapas anteriores
# através do cache.
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
# 2. Torch 2.10 + CUDA 13.0
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
# 7. Hugging Face Hub + hf-xet
#
# Usamos o mecanismo de download do Hugging Face com Xet.
# ============================================================

RUN pip install --no-cache-dir \
    "huggingface_hub[hf_xet]"

# ============================================================
# 8. Configuração do Xet
#
# O objetivo é maximizar a velocidade do download.
# ============================================================

ENV HF_XET_HIGH_PERFORMANCE=1
ENV HF_XET_NUM_CONCURRENT_RANGE_GETS=64

# Evita timeouts muito agressivos.
ENV HF_HUB_DOWNLOAD_TIMEOUT=300
ENV HF_HUB_ETAG_TIMEOUT=60
ENV HF_HUB_DISABLE_UPDATE_CHECK=1

# ============================================================
# 9. Diretório dos checkpoints
# ============================================================

RUN mkdir -p /comfyui/models/checkpoints

# ============================================================
# 10. Download Qwen Rapid AIO
#
# IMPORTANTE:
#
# O arquivo está dentro da pasta v11 do repositório.
#
# Repositório:
# Phr00t/Qwen-Image-Edit-Rapid-AIO
#
# Arquivo:
# v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors
#
# Não usamos HF_TOKEN porque o modelo é público.
# ============================================================

RUN echo "============================================================" && \
    echo "INICIANDO DOWNLOAD DO QWEN RAPID AIO" && \
    echo "============================================================" && \
    hf download \
        Phr00t/Qwen-Image-Edit-Rapid-AIO \
        v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors \
        --local-dir /comfyui/models/checkpoints

# ============================================================
# 11. Verificação do modelo
# ============================================================

RUN echo "============================================================" && \
    echo "VERIFICANDO QWEN RAPID AIO" && \
    echo "============================================================" && \
    ls -lh \
    /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors && \
    test -s \
    /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors && \
    echo "Qwen Rapid AIO: OK"

# ============================================================
# 12. Verificação do ComfyUI
# ============================================================

RUN echo "============================================================" && \
    echo "COMFYUI" && \
    echo "============================================================" && \
    git -C /comfyui rev-parse HEAD && \
    git -C /comfyui describe --tags --always

# ============================================================
# 13. Verificação Python
# ============================================================

RUN echo "============================================================" && \
    echo "PYTHON" && \
    echo "============================================================" && \
    python3.12 --version

# ============================================================
# 14. Verificação Torch / CUDA
# ============================================================

RUN echo "============================================================" && \
    echo "TORCH / CUDA" && \
    echo "============================================================" && \
    python3.12 -c "import torch; print('Torch:', torch.__version__); print('CUDA:', torch.version.cuda); print('CUDA available:', torch.cuda.is_available())"

# ============================================================
# 15. Verificação Custom Nodes
# ============================================================

RUN echo "============================================================" && \
    echo "CUSTOM NODES" && \
    echo "============================================================" && \
    test -d /comfyui/custom_nodes/ComfyUI-Image-Saver && \
    echo "Image Saver: OK" && \
    test -d /comfyui/custom_nodes/RES4LYF && \
    echo "RES4LYF: OK" && \
    test -d /comfyui/custom_nodes/rgthree-comfy && \
    echo "rgthree-comfy: OK" && \
    test -d /comfyui/custom_nodes/ComfyUI-KJNodes && \
    echo "KJNodes: OK"

# ============================================================
# 16. Diretório de trabalho
# ============================================================

WORKDIR /comfyui
