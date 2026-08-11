# ============================================================
# RunPod Serverless - ComfyUI
# Qwen Image Edit / Rapid AIO workflow
#
# Ambiente validado no Pod:
#   Python       3.12.3
#   ComfyUI      v0.26.2
#   Torch        2.10.0+cu130
#   TorchVision  0.25.0+cu130
#   TorchAudio   2.10.0+cu130
#   CUDA         13.0
# ============================================================

FROM runpod/worker-comfyui:5.8.4-base

SHELL ["/bin/bash", "-c"]

# ============================================================
# 1. ComfyUI - usar a tag validada no Pod
# ============================================================

RUN cd /comfyui && \
    git fetch --tags origin && \
    git checkout v0.26.2

# ============================================================
# 2. PyTorch CUDA 13.0
# ============================================================

RUN pip install --no-cache-dir --force-reinstall \
    torch==2.10.0 \
    torchaudio==2.10.0 \
    torchvision==0.25.0 \
    --index-url https://download.pytorch.org/whl/cu130

# ============================================================
# 3. Dependências confirmadas no Pod
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
# 4. Função robusta para instalar custom nodes em commit
#
# Primeiro tenta o commit já disponível no clone.
# Se não estiver, tenta buscar o SHA diretamente.
# ============================================================

RUN install_custom_node() { \
        REPO="$1"; \
        DIR="$2"; \
        COMMIT="$3"; \
        echo "=================================================="; \
        echo "Installing custom node: $DIR"; \
        echo "Repository: $REPO"; \
        echo "Commit: $COMMIT"; \
        echo "=================================================="; \
        git clone "$REPO" "$DIR"; \
        cd "$DIR"; \
        if ! git checkout "$COMMIT" 2>/dev/null; then \
            echo "Commit not present in clone; trying git fetch..."; \
            git fetch origin "$COMMIT" --depth=1; \
            git checkout "$COMMIT"; \
        fi; \
        echo "Installed commit:"; \
        git rev-parse HEAD; \
    }; \
    install_custom_node \
        "https://github.com/alexopus/ComfyUI-Image-Saver.git" \
        "/comfyui/custom_nodes/ComfyUI-Image-Saver" \
        "205d66a9d8035e3ad2ba6c61b7ebf7871664e472"; \
    install_custom_node \
        "https://github.com/ClownsharkBatwing/RES4LYF.git" \
        "/comfyui/custom_nodes/RES4LYF" \
        "26036f647ca15d3048a193daf99a40cecfc3820d"; \
    install_custom_node \
        "https://github.com/rgthree/rgthree-comfy.git" \
        "/comfyui/custom_nodes/rgthree-comfy" \
        "6b76ee6f2c5a007710b5a16f97c94330d6ecc871"; \
    install_custom_node \
        "https://github.com/kijai/ComfyUI-KJNodes.git" \
        "/comfyui/custom_nodes/ComfyUI-KJNodes" \
        "c2a47f161bdcecc1e6baf3412f1d116febc26ce3"

# ============================================================
# 5. Requirements dos custom nodes
# ============================================================

RUN pip install --no-cache-dir \
    -r /comfyui/custom_nodes/ComfyUI-Image-Saver/requirements.txt \
    -r /comfyui/custom_nodes/RES4LYF/requirements.txt \
    -r /comfyui/custom_nodes/rgthree-comfy/requirements.txt \
    -r /comfyui/custom_nodes/ComfyUI-KJNodes/requirements.txt

# ============================================================
# 6. Diretórios dos modelos
# ============================================================

RUN mkdir -p \
    /comfyui/models/checkpoints \
    /comfyui/models/text_encoders \
    /comfyui/models/vae \
    /comfyui/models/loras/qwen_edit

# ============================================================
# 7. Checkpoint
# ============================================================

RUN BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        comfy model download \
            --url "https://huggingface.co/Phr00t/Qwen-Image-Edit-Rapid-AIO/resolve/main/v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors" \
            --relative-path models/checkpoints \
            --filename "Qwen-Rapid-AIO-NSFW-v11.4.safetensors" && break; \
        if [ "$i" -eq 5 ]; then exit 1; fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Retrying checkpoint in ${SLEEP}s..."; sleep "$SLEEP"; \
    done

# ============================================================
# 8. Qwen VL Text Encoder
# ============================================================

RUN BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        comfy model download \
            --url "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" \
            --relative-path models/text_encoders \
            --filename "qwen_2.5_vl_7b_fp8_scaled.safetensors" && break; \
        if [ "$i" -eq 5 ]; then exit 1; fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Retrying text encoder in ${SLEEP}s..."; sleep "$SLEEP"; \
    done

# ============================================================
# 9. Qwen Image VAE
# ============================================================

RUN BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        comfy model download \
            --url "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors" \
            --relative-path models/vae \
            --filename "qwen_image_vae.safetensors" && break; \
        if [ "$i" -eq 5 ]; then exit 1; fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Retrying VAE in ${SLEEP}s..."; sleep "$SLEEP"; \
    done

# ============================================================
# 10. Next Scene LoRA
# ============================================================

RUN BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        comfy model download \
            --url "https://huggingface.co/camenduru/Qwen-Loras/resolve/main/next-scene_lora-v2-3000.safetensors" \
            --relative-path models/loras/qwen_edit \
            --filename "next-scene_lora-v2-3000.safetensors" && break; \
        if [ "$i" -eq 5 ]; then exit 1; fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Retrying Next Scene LoRA in ${SLEEP}s..."; sleep "$SLEEP"; \
    done

# ============================================================
# 11. Unblur / Upscale LoRA
# ============================================================

RUN BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        comfy model download \
            --url "https://huggingface.co/prithivMLmods/Qwen-Image-Edit-2511-Unblur-Upscale/resolve/main/Qwen-Image-Edit-Unblur-Upscale_10.safetensors" \
            --relative-path models/loras/qwen_edit \
            --filename "Qwen-Image-Edit-Unblur-Upscale_10.safetensors" && break; \
        if [ "$i" -eq 5 ]; then exit 1; fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Retrying Unblur/Upscale LoRA in ${SLEEP}s..."; sleep "$SLEEP"; \
    done

# ============================================================
# 12. Verificações finais
# ============================================================

RUN echo "===== COMFYUI =====" && \
    git -C /comfyui rev-parse HEAD && \
    git -C /comfyui describe --tags --always && \
    echo "===== TORCH =====" && \
    python3.12 -c "import torch; print('Torch:', torch.__version__); print('CUDA:', torch.version.cuda)" && \
    echo "===== CUSTOM NODES =====" && \
    git -C /comfyui/custom_nodes/ComfyUI-Image-Saver rev-parse HEAD && \
    git -C /comfyui/custom_nodes/RES4LYF rev-parse HEAD && \
    git -C /comfyui/custom_nodes/rgthree-comfy rev-parse HEAD && \
    git -C /comfyui/custom_nodes/ComfyUI-KJNodes rev-parse HEAD && \
    echo "===== MODELS =====" && \
    ls -lh /comfyui/models/checkpoints/ && \
    ls -lh /comfyui/models/text_encoders/ && \
    ls -lh /comfyui/models/vae/ && \
    ls -lh /comfyui/models/loras/qwen_edit/

# ============================================================
# 13. Limpeza
# ============================================================

RUN rm -rf /root/.cache/pip

WORKDIR /comfyui
