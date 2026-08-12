FROM runpod/worker-comfyui:5.8.4-base

SHELL ["/bin/bash", "-c"]

# ============================================================
# ComfyUI
# ============================================================

RUN cd /comfyui && \
    git fetch --tags origin && \
    git checkout v0.26.2

# ============================================================
# Torch CUDA 13
# ============================================================

RUN pip install --no-cache-dir --force-reinstall \
    torch==2.10.0 \
    torchaudio==2.10.0 \
    torchvision==0.25.0 \
    --index-url https://download.pytorch.org/whl/cu130

# ============================================================
# Image Saver
# ============================================================

RUN git clone \
    https://github.com/alexopus/ComfyUI-Image-Saver.git \
    /comfyui/custom_nodes/ComfyUI-Image-Saver && \
    pip install --no-cache-dir \
    -r /comfyui/custom_nodes/ComfyUI-Image-Saver/requirements.txt

# ============================================================
# RES4LYF
# ============================================================

RUN git clone \
    https://github.com/ClownsharkBatwing/RES4LYF.git \
    /comfyui/custom_nodes/RES4LYF && \
    pip install --no-cache-dir \
    -r /comfyui/custom_nodes/RES4LYF/requirements.txt

# ============================================================
# rgthree
# ============================================================

RUN git clone \
    https://github.com/rgthree/rgthree-comfy.git \
    /comfyui/custom_nodes/rgthree-comfy

# ============================================================
# KJNodes
# ============================================================

RUN git clone \
    https://github.com/kijai/ComfyUI-KJNodes.git \
    /comfyui/custom_nodes/ComfyUI-KJNodes && \
    pip install --no-cache-dir \
    -r /comfyui/custom_nodes/ComfyUI-KJNodes/requirements.txt

# ============================================================
# Modelo principal
# ============================================================

RUN mkdir -p /comfyui/models/checkpoints

RUN BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        comfy model download \
            --url "https://huggingface.co/Phr00t/Qwen-Image-Edit-Rapid-AIO/resolve/main/v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors" \
            --relative-path models/checkpoints \
            --filename "Qwen-Rapid-AIO-NSFW-v11.4.safetensors" && \
        break; \
        if [ "$i" -eq 5 ]; then \
            echo "ERROR: model download failed after 5 attempts" >&2; \
            exit 1; \
        fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Retrying in ${SLEEP}s..." >&2; \
        sleep "$SLEEP"; \
    done

# ============================================================
# Verificação
# ============================================================

RUN python3.12 -c "import torch; print('Torch:', torch.__version__); print('CUDA:', torch.version.cuda)"

RUN ls -lh \
    /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors

WORKDIR /comfyui
