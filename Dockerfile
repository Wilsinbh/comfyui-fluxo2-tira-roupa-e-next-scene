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
# Esta imagem prepara ComfyUI + custom nodes + modelos.
# O worker/handler Serverless continua sendo o da imagem base.
# ============================================================

FROM runpod/worker-comfyui:5.8.4-base

SHELL ["/bin/bash", "-c"]

# ============================================================
# 1. Fixar ComfyUI na tag VALIDADA
#
# O Pod mostrou:
#   v0.26.2
#   7ffd7983e72de29d90431fc746db9b41a4299d5e
#
# NÃO fazer git fetch do SHA diretamente:
# isso falhou no build com "not our ref".
# ============================================================

RUN cd /comfyui && \
    git fetch --tags origin && \
    git checkout v0.26.2

# ============================================================
# 2. PyTorch / CUDA 13.0
# ============================================================

RUN pip install --no-cache-dir --force-reinstall \
    torch==2.10.0 \
    torchaudio==2.10.0 \
    torchvision==0.25.0 \
    --index-url https://download.pytorch.org/whl/cu130

# ============================================================
# 3. Dependências do ambiente VALIDADO no Pod
#
# Estas versões foram verificadas com pip freeze.
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
#
# IMPORTANTE:
# Este é o repositório que corresponde ao node usado
# pelo workflow: "Image Saver Metadata" / "Image Saver Simple".
#
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
#
# O workflow usa:
#   ClownsharKSampler_Beta
#
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
#
# O workflow usa:
#   Power Lora Loader (rgthree)
#
# Commit validado:
# 6b76ee6f2c5a007710b5a16f97c94330d6ecc871
# ============================================================

RUN git clone https://github.com/rgthree/rgthree-comfy.git \
    /comfyui/custom_nodes/rgthree-comfy && \
    cd /comfyui/custom_nodes/rgthree-comfy && \
    git checkout 6b76ee6f2c5a007710b5a16f97c94330d6ecc871

# ============================================================
# 7. ComfyUI-KJNodes
#
# O workflow usa:
#   WidgetToString
#   INTConstant
#
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
#
# Estrutura conferida no workflow:
#
# models/
# ├── checkpoints/
# │   └── Qwen-Rapid-AIO-NSFW-v11.4.safetensors
# ├── text_encoders/
# │   └── qwen_2.5_vl_7b_fp8_scaled.safetensors
# ├── vae/
# │   └── qwen_image_vae.safetensors
# └── loras/
#     └── qwen_edit/
#         ├── next-scene_lora-v2-3000.safetensors
#         └── Qwen-Image-Edit-Unblur-Upscale_10.safetensors
# ============================================================

RUN mkdir -p \
    /comfyui/models/checkpoints \
    /comfyui/models/text_encoders \
    /comfyui/models/vae \
    /comfyui/models/loras/qwen_edit

# ============================================================
# 9. Download dos modelos
#
# Usamos "comfy model download" porque é o mecanismo disponível
# na imagem RunPod/ComfyUI e foi usado no Dockerfile de referência.
#
# Cada modelo possui até 5 tentativas.
# ============================================================

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
        echo "Checkpoint download failed; retrying in ${SLEEP}s..." >&2; \
        sleep "$SLEEP"; \
    done

RUN BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        comfy model download \
            --url "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" \
            --relative-path models/text_encoders \
            --filename "qwen_2.5_vl_7b_fp8_scaled.safetensors" && \
        break; \
        if [ "$i" -eq 5 ]; then \
            echo "ERROR: text encoder download failed after 5 attempts" >&2; \
            exit 1; \
        fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Text encoder download failed; retrying in ${SLEEP}s..." >&2; \
        sleep "$SLEEP"; \
    done

RUN BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        comfy model download \
            --url "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors" \
            --relative-path models/vae \
            --filename "qwen_image_vae.safetensors" && \
        break; \
        if [ "$i" -eq 5 ]; then \
            echo "ERROR: VAE download failed after 5 attempts" >&2; \
            exit 1; \
        fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "VAE download failed; retrying in ${SLEEP}s..." >&2; \
        sleep "$SLEEP"; \
    done

RUN BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        comfy model download \
            --url "https://huggingface.co/camenduru/Qwen-Loras/resolve/main/next-scene_lora-v2-3000.safetensors" \
            --relative-path models/loras/qwen_edit \
            --filename "next-scene_lora-v2-3000.safetensors" && \
        break; \
        if [ "$i" -eq 5 ]; then \
            echo "ERROR: next-scene LoRA download failed after 5 attempts" >&2; \
            exit 1; \
        fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Next-scene LoRA download failed; retrying in ${SLEEP}s..." >&2; \
        sleep "$SLEEP"; \
    done

RUN BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        comfy model download \
            --url "https://huggingface.co/prithivMLmods/Qwen-Image-Edit-2511-Unblur-Upscale/resolve/main/Qwen-Image-Edit-Unblur-Upscale_10.safetensors" \
            --relative-path models/loras/qwen_edit \
            --filename "Qwen-Image-Edit-Unblur-Upscale_10.safetensors" && \
        break; \
        if [ "$i" -eq 5 ]; then \
            echo "ERROR: Unblur/Upscale LoRA download failed after 5 attempts" >&2; \
            exit 1; \
        fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Unblur/Upscale LoRA download failed; retrying in ${SLEEP}s..." >&2; \
        sleep "$SLEEP"; \
    done

# ============================================================
# 10. Verificação do ComfyUI
# ============================================================

RUN echo "===== COMFYUI =====" && \
    git -C /comfyui rev-parse HEAD && \
    git -C /comfyui describe --tags --always

# ============================================================
# 11. Verificação Torch / CUDA
# ============================================================

RUN echo "===== TORCH / CUDA =====" && \
    python3.12 -c "import torch; print('Torch:', torch.__version__); print('CUDA:', torch.version.cuda)"

# ============================================================
# 12. Verificação dos custom nodes
# ============================================================

RUN echo "===== CUSTOM NODES =====" && \
    echo "Image Saver:" && \
    git -C /comfyui/custom_nodes/ComfyUI-Image-Saver rev-parse HEAD && \
    echo "RES4LYF:" && \
    git -C /comfyui/custom_nodes/RES4LYF rev-parse HEAD && \
    echo "rgthree-comfy:" && \
    git -C /comfyui/custom_nodes/rgthree-comfy rev-parse HEAD && \
    echo "KJNodes:" && \
    git -C /comfyui/custom_nodes/ComfyUI-KJNodes rev-parse HEAD

# ============================================================
# 13. Verificação dos arquivos dos modelos
# ============================================================

RUN echo "===== CHECKPOINT =====" && \
    ls -lh /comfyui/models/checkpoints/Qwen-Rapid-AIO-NSFW-v11.4.safetensors && \
    echo "===== TEXT ENCODER =====" && \
    ls -lh /comfyui/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors && \
    echo "===== VAE =====" && \
    ls -lh /comfyui/models/vae/qwen_image_vae.safetensors && \
    echo "===== LORAS =====" && \
    ls -lh /comfyui/models/loras/qwen_edit/

# ============================================================
# 14. Verificação dos nodes usados pelo workflow
#
# Não executamos o workflow no build.
# Apenas confirmamos que os módulos dos custom nodes estão presentes.
# ============================================================

RUN test -f /comfyui/custom_nodes/ComfyUI-Image-Saver/__init__.py && \
    test -f /comfyui/custom_nodes/RES4LYF/__init__.py && \
    test -f /comfyui/custom_nodes/rgthree-comfy/__init__.py && \
    test -f /comfyui/custom_nodes/ComfyUI-KJNodes/__init__.py && \
    echo "Custom nodes: OK"

# ============================================================
# 15. Limpeza
# ============================================================

RUN rm -rf /root/.cache/pip

WORKDIR /comfyui
