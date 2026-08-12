# ============================================================
# COMFYUI SERVERLESS - FLUXO COMPLETO
#
# ComfyUI v0.26.2
# Torch 2.10.0 + CUDA 13.0
# RTX Blackwell
#
# Custom Nodes:
#   - ComfyUI-Image-Saver
#   - RES4LYF
#   - rgthree-comfy
#   - ComfyUI-KJNodes
#
# Models:
#   - Qwen Rapid AIO NSFW v11.4
#   - Qwen 2.5 VL 7B FP8
#   - Qwen Image VAE
#   - Next Scene LoRA v2
#   - Unblur/Upscale LoRA
# ============================================================

FROM runpod/worker-comfyui:5.8.4-base

SHELL ["/bin/bash", "-c"]

# ============================================================
# 1. COMFYUI
# ============================================================

RUN cd /comfyui && \
    git fetch --tags origin && \
    git checkout v0.26.2

# ============================================================
# 2. TORCH 2.10 + CUDA 13.0
# ============================================================

RUN pip install --no-cache-dir --force-reinstall \
    torch==2.10.0 \
    torchaudio==2.10.0 \
    torchvision==0.25.0 \
    --index-url https://download.pytorch.org/whl/cu130

# ============================================================
# 3. COMFYUI IMAGE SAVER
# ============================================================

RUN git clone \
    https://github.com/giriss/comfy-image-saver.git \
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
# 5. RGTHREE
# ============================================================

RUN git clone \
    https://github.com/rgthree/rgthree-comfy.git \
    /comfyui/custom_nodes/rgthree-comfy

# ============================================================
# 6. KJNODES
# ============================================================

RUN git clone \
    https://github.com/kijai/ComfyUI-KJNodes.git \
    /comfyui/custom_nodes/ComfyUI-KJNodes && \
    pip install --no-cache-dir \
    -r /comfyui/custom_nodes/ComfyUI-KJNodes/requirements.txt

# ============================================================
# 7. HUGGING FACE + XET
# ============================================================

RUN pip install --no-cache-dir \
    "huggingface_hub[hf_xet]"

# ============================================================
# 8. DOWNLOAD PERFORMANCE
# ============================================================

ENV HF_XET_HIGH_PERFORMANCE=1
ENV HF_XET_NUM_CONCURRENT_RANGE_GETS=64

ENV HF_HUB_DOWNLOAD_TIMEOUT=300
ENV HF_HUB_ETAG_TIMEOUT=60
ENV HF_HUB_DISABLE_UPDATE_CHECK=1

# ============================================================
# 9. DIRETÓRIOS
# ============================================================

RUN mkdir -p \
    /comfyui/models/checkpoints \
    /comfyui/models/text_encoders \
    /comfyui/models/vae \
    /comfyui/models/loras

# ============================================================
# 10. QWEN RAPID AIO
#
# Phr00t/Qwen-Image-Edit-Rapid-AIO
# v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors
#
# ~27 GB
# ============================================================

RUN echo "============================================================" && \
    echo "DOWNLOAD: QWEN RAPID AIO" && \
    echo "============================================================" && \
    hf download \
        Phr00t/Qwen-Image-Edit-Rapid-AIO \
        v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors \
        --local-dir /comfyui/models/checkpoints && \
    mv \
        /comfyui/models/checkpoints/v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors \
        /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors && \
    rmdir /comfyui/models/checkpoints/v11

# ============================================================
# 11. QWEN 2.5 VL 7B FP8
#
# 9.38 GB
#
# Origem equivalente ao arquivo que você já utilizou.
# ============================================================

RUN echo "============================================================" && \
    echo "DOWNLOAD: QWEN 2.5 VL 7B FP8" && \
    echo "============================================================" && \
    hf download \
        Cashmitki/qwen \
        qwen_2.5_vl_7b_fp8_scaled.safetensors \
        --local-dir /tmp/qwen-vl && \
    mv \
        /tmp/qwen-vl/qwen_2.5_vl_7b_fp8_scaled.safetensors \
        /comfyui/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors && \
    rm -rf /tmp/qwen-vl

# ============================================================
# 12. QWEN IMAGE VAE
#
# 254 MB
# ============================================================

RUN echo "============================================================" && \
    echo "DOWNLOAD: QWEN IMAGE VAE" && \
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
# 13. NEXT SCENE LORA V2
#
# camenduru/Qwen-Loras
# 295 MB
# ============================================================

RUN echo "============================================================" && \
    echo "DOWNLOAD: NEXT SCENE LORA V2" && \
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
# 14. UNBLUR / UPSCALE LORA
#
# prithivMLmods/Qwen-Image-Edit-2511-Unblur-Upscale
# 236 MB
# ============================================================

RUN echo "============================================================" && \
    echo "DOWNLOAD: UNBLUR / UPSCALE LORA" && \
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
# 15. VERIFICAÇÃO DOS MODELOS
# ============================================================

RUN echo "============================================================" && \
    echo "VERIFICANDO MODELOS" && \
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
# 16. VERIFICAÇÃO ESPECÍFICA
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
# 17. VERIFICAÇÃO COMFYUI
# ============================================================

RUN echo "============================================================" && \
    echo "COMFYUI" && \
    echo "============================================================" && \
    git -C /comfyui rev-parse HEAD && \
    git -C /comfyui describe --tags --always

# ============================================================
# 18. VERIFICAÇÃO PYTHON
# ============================================================

RUN python3.12 --version

# ============================================================
# 19. VERIFICAÇÃO TORCH / CUDA
# ============================================================

RUN python3.12 -c "\
import torch; \
print('Torch:', torch.__version__); \
print('CUDA:', torch.version.cuda); \
print('CUDA available:', torch.cuda.is_available())"

# ============================================================
# 20. VERIFICAÇÃO CUSTOM NODES
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
# 21. WORKDIR
# ============================================================

WORKDIR /comfyui
