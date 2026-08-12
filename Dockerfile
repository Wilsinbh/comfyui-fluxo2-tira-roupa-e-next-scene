# ============================================================
# COMFYUI SERVERLESS
# FLUXO: QWEN IMAGE EDIT + NEXT SCENE
#
# Base:
#   runpod/worker-comfyui:5.8.4-base
#
# ComfyUI:
#   v0.26.2
#
# Python:
#   3.12
#
# Torch:
#   2.10.0 + CUDA 13.0
#
# GPU alvo:
#   NVIDIA Blackwell
#
# ============================================================

FROM runpod/worker-comfyui:5.8.4-base

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /comfyui

# ============================================================
# 1. COMFYUI v0.26.2
# ============================================================

RUN cd /comfyui && \
    git fetch --tags origin && \
    git checkout v0.26.2

# ============================================================
# 2. TORCH 2.10.0 + CUDA 13.0
# ============================================================

RUN pip install --no-cache-dir --force-reinstall \
    torch==2.10.0 \
    torchaudio==2.10.0 \
    torchvision==0.25.0 \
    --index-url https://download.pytorch.org/whl/cu130

# ============================================================
# 3. DESATIVAR VRAM DINÂMICA
#
# A RTX Pro Blackwell possui VRAM suficiente para manter
# os modelos residentes.
# ============================================================

RUN comfy set-default /comfyui \
    --launch-extras="--disable-dynamic-vram"

# ============================================================
# 4. COMFYUI IMAGE SAVER
#
# Fork correto:
# alexopus/ComfyUI-Image-Saver
#
# Contém:
# Image Saver Metadata
# Image Saver Simple
# etc.
# ============================================================

RUN git clone \
    https://github.com/alexopus/ComfyUI-Image-Saver.git \
    /comfyui/custom_nodes/ComfyUI-Image-Saver && \
    pip install --no-cache-dir \
    -r /comfyui/custom_nodes/ComfyUI-Image-Saver/requirements.txt

# ============================================================
# 5. RES4LYF
# ============================================================

RUN git clone \
    https://github.com/ClownsharkBatwing/RES4LYF.git \
    /comfyui/custom_nodes/RES4LYF && \
    pip install --no-cache-dir \
    -r /comfyui/custom_nodes/RES4LYF/requirements.txt

# ============================================================
# 6. RGTHREE
# ============================================================

RUN git clone \
    https://github.com/rgthree/rgthree-comfy.git \
    /comfyui/custom_nodes/rgthree-comfy

# ============================================================
# 7. KJNODES
# ============================================================

RUN git clone \
    https://github.com/kijai/ComfyUI-KJNodes.git \
    /comfyui/custom_nodes/ComfyUI-KJNodes && \
    pip install --no-cache-dir \
    -r /comfyui/custom_nodes/ComfyUI-KJNodes/requirements.txt

# ============================================================
# 8. SAGEATTN3
#
# Wheel validado no Pod:
# torch 2.10.0 + CUDA 13.0
# Blackwell
# ============================================================

RUN pip install --no-cache-dir \
    "huggingface_hub[cli]"

RUN hf download \
    Seryoger/Sageattention-3-cu130-5090-endpoint \
    sageattn3-1.0.0-cp312-cp312-linux_x86_64.whl \
    --local-dir /tmp/sageattn3 && \
    pip install --no-cache-dir \
    /tmp/sageattn3/sageattn3-1.0.0-cp312-cp312-linux_x86_64.whl && \
    rm -rf /tmp/sageattn3

# ============================================================
# 9. HF-XET
#
# Usado para os downloads grandes dos modelos.
# ============================================================

RUN pip install --no-cache-dir \
    "huggingface_hub[hf_xet]"

ENV HF_XET_HIGH_PERFORMANCE=1
ENV HF_XET_NUM_CONCURRENT_RANGE_GETS=64

ENV HF_HUB_DOWNLOAD_TIMEOUT=300
ENV HF_HUB_ETAG_TIMEOUT=60
ENV HF_HUB_DISABLE_UPDATE_CHECK=1

# ============================================================
# 10. DIRETÓRIOS
# ============================================================

RUN mkdir -p \
    /comfyui/models/checkpoints \
    /comfyui/models/text_encoders \
    /comfyui/models/vae \
    /comfyui/models/loras

# ============================================================
# 11. QWEN RAPID AIO
#
# 28.4 GB
#
# Phr00t/Qwen-Image-Edit-Rapid-AIO
# ============================================================

RUN echo "============================================================" && \
    echo "DOWNLOAD QWEN RAPID AIO" && \
    echo "============================================================" && \
    hf download \
        Phr00t/Qwen-Image-Edit-Rapid-AIO \
        v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors \
        --local-dir /tmp/qwen-rapid && \
    mv \
        /tmp/qwen-rapid/v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors \
        /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors && \
    rm -rf /tmp/qwen-rapid

# ============================================================
# 12. QWEN 2.5 VL 7B FP8
#
# 9.38 GB
#
# art1455/QWEN
# ============================================================

RUN echo "============================================================" && \
    echo "DOWNLOAD QWEN 2.5 VL 7B FP8" && \
    echo "============================================================" && \
    hf download \
        art1455/QWEN \
        qwen_2.5_vl_7b_fp8_scaled.safetensors \
        --local-dir /tmp/qwen-vl && \
    mv \
        /tmp/qwen-vl/qwen_2.5_vl_7b_fp8_scaled.safetensors \
        /comfyui/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors && \
    rm -rf /tmp/qwen-vl

# ============================================================
# 13. QWEN IMAGE VAE
#
# 254 MB
#
# art1455/QWEN
# ============================================================

RUN echo "============================================================" && \
    echo "DOWNLOAD QWEN IMAGE VAE" && \
    echo "============================================================" && \
    hf download \
        art1455/QWEN \
        qwen_image_vae.safetensors \
        --local-dir /tmp/qwen-vae && \
    mv \
        /tmp/qwen-vae/qwen_image_vae.safetensors \
        /comfyui/models/vae/qwen_image_vae.safetensors && \
    rm -rf /tmp/qwen-vae

# ============================================================
# 14. NEXT SCENE LORA
#
# 295 MB
#
# camenduru/Qwen-Loras
# ============================================================

RUN echo "============================================================" && \
    echo "DOWNLOAD NEXT SCENE LORA" && \
    echo "============================================================" && \
    hf download \
        camenduru/Qwen-Loras \
        next-scene_lora-v2-3000.safetensors \
        --local-dir /tmp/next-scene && \
    mv \
        /tmp/next-scene/next-scene_lora-v2-3000.safetensors \
        /comfyui/models/loras/next-scene_lora-v2-3000.safetensors && \
    rm -rf /tmp/next-scene

# ============================================================
# 15. UNBLUR / UPSCALE LORA
#
# 236 MB
#
# prithivMLmods/Qwen-Image-Edit-2511-Unblur-Upscale
# ============================================================

RUN echo "============================================================" && \
    echo "DOWNLOAD UNBLUR / UPSCALE LORA" && \
    echo "============================================================" && \
    hf download \
        prithivMLmods/Qwen-Image-Edit-2511-Unblur-Upscale \
        Qwen-Image-Edit-Unblur-Upscale_10.safetensors \
        --local-dir /tmp/unblur && \
    mv \
        /tmp/unblur/Qwen-Image-Edit-Unblur-Upscale_10.safetensors \
        /comfyui/models/loras/Qwen-Image-Edit-Unblur-Upscale_10.safetensors && \
    rm -rf /tmp/unblur

# ============================================================
# 16. VERIFICAR MODELOS
# ============================================================

RUN echo "============================================================" && \
    echo "MODELOS INSTALADOS" && \
    echo "============================================================" && \
    echo "" && \
    echo "CHECKPOINTS:" && \
    ls -lh /comfyui/models/checkpoints/ && \
    echo "" && \
    echo "TEXT ENCODERS:" && \
    ls -lh /comfyui/models/text_encoders/ && \
    echo "" && \
    echo "VAE:" && \
    ls -lh /comfyui/models/vae/ && \
    echo "" && \
    echo "LORAS:" && \
    ls -lh /comfyui/models/loras/

# ============================================================
# 17. VALIDAR ARQUIVOS
# ============================================================

RUN test -s \
    /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors && \
    test -s \
    /comfyui/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors && \
    test -s \
    /comfyui/models/vae/qwen_image_vae.safetensors && \
    test -s \
    /comfyui/models/loras/next-scene_lora-v2-3000.safetensors && \
    test -s \
    /comfyui/models/loras/Qwen-Image-Edit-Unblur-Upscale_10.safetensors && \
    echo "============================================================" && \
    echo "TODOS OS MODELOS: OK" && \
    echo "============================================================"

# ============================================================
# 18. VALIDAR COMFYUI
# ============================================================

RUN echo "============================================================" && \
    echo "COMFYUI VERSION" && \
    echo "============================================================" && \
    git -C /comfyui rev-parse HEAD && \
    git -C /comfyui describe --tags --always

# ============================================================
# 19. VALIDAR PYTHON
# ============================================================

RUN echo "============================================================" && \
    echo "PYTHON" && \
    echo "============================================================" && \
    python3.12 --version

# ============================================================
# 20. VALIDAR TORCH / CUDA
# ============================================================

RUN echo "============================================================" && \
    echo "TORCH / CUDA" && \
    echo "============================================================" && \
    python3.12 -c "\
import torch; \
print('Torch:', torch.__version__); \
print('CUDA:', torch.version.cuda); \
print('CUDA available:', torch.cuda.is_available())"

# ============================================================
# 21. VALIDAR CUSTOM NODES
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
# 22. VALIDAR SAGEATTN3
# ============================================================

RUN python3.12 -c "import sageattn3; print('sageattn3: OK')"

# ============================================================
# 23. FINAL
# ============================================================

WORKDIR /comfyui
