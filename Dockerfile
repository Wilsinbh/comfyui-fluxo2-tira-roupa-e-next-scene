# ============================================================
# ETAPA 3A
# ComfyUI + Custom Nodes + Qwen Rapid AIO
#
# IMPORTANTE:
# Não usar FROM registry.runpod.net/... da Etapa 2.
# O RunPod Build retorna 401 ao tentar acessar essa imagem.
#
# As etapas anteriores serão reaproveitadas pelo cache do BuildKit.
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
# 7. Diretório do checkpoint
# ============================================================

RUN mkdir -p /comfyui/models/checkpoints

# ============================================================
# 8. Download Qwen Rapid AIO
#
# Usamos wget diretamente.
#
# O modelo é grande, então:
# - timeout de conexão: 60s
# - múltiplas tentativas
# - retry automático
# - download direto do Hugging Face
# ============================================================

RUN URL="https://huggingface.co/Phr00t/Qwen-Image-Edit-Rapid-AIO/resolve/main/v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors" && \
    DEST="/comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors" && \
    BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        echo "============================================================"; \
        echo "Qwen Rapid AIO - tentativa $i/5"; \
        echo "============================================================"; \
        if wget \
            --progress=dot:giga \
            --timeout=60 \
            --tries=3 \
            --continue \
            -O "$DEST" \
            "$URL"; then \
            echo "Download concluído."; \
            break; \
        fi; \
        if [ "$i" -eq 5 ]; then \
            echo "ERRO: download falhou após 5 tentativas." >&2; \
            exit 1; \
        fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Download falhou. Nova tentativa em ${SLEEP}s..." >&2; \
        sleep "$SLEEP"; \
    done

# ============================================================
# 9. Verificação do modelo
# ============================================================

RUN echo "============================================================" && \
    echo "CHECKPOINT INSTALADO" && \
    ls -lh /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors && \
    echo "============================================================"

# ============================================================
# 10. Verificação final
# ============================================================

RUN echo "===== COMFYUI =====" && \
    git -C /comfyui rev-parse HEAD && \
    git -C /comfyui describe --tags --always && \
    echo "===== TORCH / CUDA =====" && \
    python3.12 -c "import torch; print('Torch:', torch.__version__); print('CUDA:', torch.version.cuda)" && \
    echo "===== CUSTOM NODES =====" && \
    test -d /comfyui/custom_nodes/ComfyUI-Image-Saver && \
    test -d /comfyui/custom_nodes/RES4LYF && \
    test -d /comfyui/custom_nodes/rgthree-comfy && \
    test -d /comfyui/custom_nodes/ComfyUI-KJNodes && \
    echo "Custom Nodes: OK"

WORKDIR /comfyui
