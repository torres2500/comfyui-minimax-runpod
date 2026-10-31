FROM huchukato/comfyui-qwenvl-runpod:mmh3-qwen21
COPY download-minimax-h3-models.sh /usr/local/bin/download-minimax-h3-models.sh
RUN sed -i 's/\r$//' /usr/local/bin/download-minimax-h3-models.sh && chmod +x /usr/local/bin/download-minimax-h3-models.sh
