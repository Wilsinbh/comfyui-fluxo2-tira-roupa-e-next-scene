# ============================================================
# RunPod Serverless - ComfyUI
# Qwen Image Edit / Rapid AIO workflow
#
# Ambiente validado no Pod:
#   Python       3.12.3
#   ComfyUI      v0.26.2
#   ComfyUI SHA  7ffd7983e72de29d90431fc746db9b41a4299d5e
#   Torch        2.10.0+cu130
#   TorchVision  0.25.0+cu130
#   TorchAudio   2.10.0+cu130
#   CUDA         13.0
#
# IMPORTANTE:
# Esta imagem prepara ComfyUI + custom nodes + modelos.
# O handler/API do Serverless será adicionado em uma etapa separada.
# ============================================================

FROM runpod/worker-comfyui:5.8.4-base

SHELL ["/bin/bash", "-c"]

# ============================================================
# 1. Fixar ComfyUI na versão validada
# ============================================================

RUN cd /comfyui && \
    git fetch origin 7ffd7983e72de29d90431fc746db9b41a4299d5e && \
    git checkout 7ffd7983e72de29d90431fc746db9b41a4299d5e

# ============================================================
# 2. PyTorch CUDA 13.0 - ambiente validado
# ============================================================

RUN pip install --no-cache-dir --force-reinstall \
    torch==2.10.0 \
    torchaudio==2.10.0 \
    torchvision==0.25.0 \
    --index-url https://download.pytorch.org/whl/cu130

# ============================================================
# 3. Dependências Python observadas no ambiente funcional
# ============================================================

RUN pip install --no-cache-dir \
    numpy==2.5.0 \
    scipy==1.18.0 \
    opencv-python==4.13.0.92 \
    opencv-python-headless==4.13.0.92 \
    matplotlib==3.11.0 \
    PyWavelets==1.9.0 \
    pillow==12.2.0 \
    piexif==1.1.3 \
    color-matcher==0.6.0 \
    mss==10.2.0 \
    kornia==0.8.3 \
    kornia_rs==0.1.14 \
    torchsde==0.2.6 \
    safetensors==0.8.0 \
    transformers==5.12.1

# ============================================================
# 4. ComfyUI Image Saver
# Repositório: alexopus/ComfyUI-Image-Saver
# Commit validado:
# 205d66a9d8035e3ad2ba6c61b7ebf7871664e472
# ============================================================

RUN git clone https://github.com/alexopus/ComfyUI-Image-Saver.git \
        /comfyui/custom_nodes/ComfyUI-Image-Saver && \
    cd /comfyui/custom_nodes/ComfyUI-Image-Saver && \
    git checkout 205d66a9d8035e3ad2ba6c61b7ebf7871664e472 && \
    pip install --no-cache-dir -r requirements.txt

# ============================================================
# 5. RES4LYF
# Commit validado:
# 26036f647ca15d3048a193daf99a40cecfc3820d
# ============================================================

RUN git clone https://github.com/ClownsharkBatwing/RES4LYF.git \
        /comfyui/custom_nodes/RES4LYF && \
    cd /comfyui/custom_nodes/RES4LYF && \
    git checkout 26036f647ca15d3048a193daf99a40cecfc3820d && \
    pip install --no-cache-dir -r requirements.txt

# ============================================================
# 6. rgthree-comfy
# Commit validado:
# 6b76ee6f2c5a007710b5a16f97c94330d6ecc871
# ============================================================

RUN git clone https://github.com/rgthree/rgthree-comfy.git \
        /comfyui/custom_nodes/rgthree-comfy && \
    cd /comfyui/custom_nodes/rgthree-comfy && \
    git checkout 6b76ee6f2c5a007710b5a16f97c94330d6ecc871

# ============================================================
# 7. ComfyUI-KJNodes
# Commit validado:
# c2a47f161bdcecc1e6baf3412f1d116febc26ce3
# ============================================================

RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git \
        /comfyui/custom_nodes/ComfyUI-KJNodes && \
    cd /comfyui/custom_nodes/ComfyUI-KJNodes && \
    git checkout c2a47f161bdcecc1e6baf3412f1d116febc26ce3 && \
    pip install --no-cache-dir -r requirements.txt

# ============================================================
# 8. Diretórios dos modelos
# ============================================================

RUN mkdir -p \
    /comfyui/models/checkpoints \
    /comfyui/models/text_encoders \
    /comfyui/models/vae \
    /comfyui/models/loras/qwen_edit

# ============================================================
# 9. Script de download com retry
# ============================================================

RUN cat > /tmp/download_model.sh <<'EOF'
#!/bin/bash
set -e

URL="$1"
DEST="$2"

MAX_ATTEMPTS=5
BACKOFFS=(10 20 30 60 90)

mkdir -p "$(dirname "$DEST")"

for ((i=1; i<=MAX_ATTEMPTS; i++)); do
    echo "=================================================="
    echo "Downloading: $URL"
    echo "Destination: $DEST"
    echo "Attempt: $i/$MAX_ATTEMPTS"
    echo "=================================================="

    if wget \
        --progress=dot:giga \
        --timeout=60 \
        --tries=3 \
        -O "$DEST" \
        "$URL"; then
        echo "Download successful."
        exit 0
    fi

    if [ "$i" -eq "$MAX_ATTEMPTS" ]; then
        echo "ERROR: download failed after $MAX_ATTEMPTS attempts." >&2
        exit 1
    fi

    SLEEP="${BACKOFFS[$((i-1))]}"
    echo "Download failed; retrying in ${SLEEP}s..." >&2
    sleep "$SLEEP"
done
EOF

RUN chmod +x /tmp/download_model.sh

# ============================================================
# 10. Checkpoint
# ============================================================

RUN /tmp/download_model.sh \
    "https://huggingface.co/Phr00t/Qwen-Image-Edit-Rapid-AIO/resolve/main/v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors" \
    "/comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors"

# ============================================================
# 11. Qwen VL Text Encoder
# ============================================================

RUN /tmp/download_model.sh \
    "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" \
    "/comfyui/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"

# ============================================================
# 12. Qwen Image VAE
# ============================================================

RUN /tmp/download_model.sh \
    "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors" \
    "/comfyui/models/vae/qwen_image_vae.safetensors"

# ============================================================
# 13. LoRA - Next Scene
# ============================================================

RUN /tmp/download_model.sh \
    "https://huggingface.co/camenduru/Qwen-Loras/resolve/main/next-scene_lora-v2-3000.safetensors" \
    "/comfyui/models/loras/qwen_edit/next-scene_lora-v2-3000.safetensors"

# ============================================================
# 14. LoRA - Unblur / Upscale
# ============================================================

RUN /tmp/download_model.sh \
    "https://huggingface.co/prithivMLmods/Qwen-Image-Edit-2511-Unblur-Upscale/resolve/main/Qwen-Image-Edit-Unblur-Upscale_10.safetensors" \
    "/comfyui/models/loras/qwen_edit/Qwen-Image-Edit-Unblur-Upscale_10.safetensors"

# ============================================================
# 15. Verificações finais
# ============================================================

RUN echo "===== COMFYUI =====" && \
    git -C /comfyui rev-parse HEAD && \
    echo "===== TORCH =====" && \
    python3.12 -c "import torch; print('Torch:', torch.__version__); print('CUDA:', torch.version.cuda)" && \
    echo "===== CUSTOM NODES =====" && \
    git -C /comfyui/custom_nodes/ComfyUI-Image-Saver rev-parse HEAD && \
    git -C /comfyui/custom_nodes/RES4LYF rev-parse HEAD && \
    git -C /comfyui/custom_nodes/rgthree-comfy rev-parse HEAD && \
    git -C /comfyui/custom_nodes/ComfyUI-KJNodes rev-parse HEAD && \
    echo "===== MODELS =====" && \
    ls -lh /comfyui/models/checkpoints && \
    ls -lh /comfyui/models/text_encoders && \
    ls -lh /comfyui/models/vae && \
    ls -lh /comfyui/models/loras/qwen_edit

# ============================================================
# 16. Limpeza
# ============================================================

RUN rm -f /tmp/download_model.sh && \
    rm -rf /root/.cache/pip

WORKDIR /comfyui
