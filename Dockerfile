# ============================================================
# ETAPA 3A
# Etapa 2 + Qwen Rapid AIO
# ============================================================

FROM registry.runpod.net/wilsinbh-comfyui-fluxo2-tira-roupa-e-next-scene-main-dockerfile:c316c84ff

SHELL ["/bin/bash", "-c"]

# ============================================================
# Diretório do checkpoint
# ============================================================

RUN mkdir -p /comfyui/models/checkpoints

# ============================================================
# Download do Qwen Rapid AIO
#
# SOMENTE este modelo será adicionado nesta imagem.
# ============================================================

RUN comfy model download \
    --url "https://huggingface.co/Phr00t/Qwen-Image-Edit-Rapid-AIO/resolve/main/v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors" \
    --relative-path models/checkpoints \
    --filename "Qwen-Rapid-AIO-NSFW-v11.4.safetensors"

# ============================================================
# Verificação
# ============================================================

RUN echo "============================================" && \
    echo "QWEN RAPID AIO" && \
    ls -lh /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors && \
    echo "============================================"

WORKDIR /comfyui
