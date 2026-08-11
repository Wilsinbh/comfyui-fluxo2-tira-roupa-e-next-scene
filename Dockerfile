# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# install custom nodes into comfyui
RUN comfy node install --exit-on-fail comfyui-kjnodes@1.1.9 --mode remote || (echo "WARN: comfyui-kjnodes@1.1.9 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-kjnodes --mode remote)
RUN comfy node install --exit-on-fail comfyui-image-saver@1.16.0 || (echo "WARN: comfyui-image-saver@1.16.0 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-image-saver)
RUN git clone https://github.com/ClownsharkBatwing/RES4LYF /comfyui/custom_nodes/RES4LYF && cd /comfyui/custom_nodes/RES4LYF && (git checkout 46de917234f9fef3f2ab411c41e07aa3c633f4f7 2>/dev/null || (git fetch origin 46de917234f9fef3f2ab411c41e07aa3c633f4f7 --depth=1 && git checkout 46de917234f9fef3f2ab411c41e07aa3c633f4f7) || echo "WARN: commit 46de917234f9fef3f2ab411c41e07aa3c633f4f7 unreachable in https://github.com/ClownsharkBatwing/RES4LYF, falling back to default branch HEAD")
RUN comfy node install --exit-on-fail rgthree-comfy@1.0.2510052058 || (echo "WARN: rgthree-comfy@1.0.2510052058 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail rgthree-comfy)

# download models into comfyui
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Phr00t/Qwen-Image-Edit-Rapid-AIO/resolve/main/v11/Qwen-Rapid-AIO-NSFW-v11.4.safetensors' --relative-path models/checkpoints --filename 'Qwen-Rapid-AIO-NSFW-v11.4.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/
