FROM registry.runpod.net/wilsinbh-comfyui-fluxo2-tira-roupa-e-next-scene-main-dockerfile:c316c84ff

SHELL ["/bin/bash", "-c"]

# ============================================================
# ETAPA 3.1
# Adiciona somente o checkpoint principal
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
            echo "ERROR: checkpoint download failed after 5 attempts" >&2; \
            exit 1; \
        fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Download failed. Retrying in ${SLEEP}s..." >&2; \
        sleep "$SLEEP"; \
    done

# ============================================================
# Verificação
# ============================================================

RUN echo "===== CHECKPOINT =====" && \
    ls -lh /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors

WORKDIR /comfyui
