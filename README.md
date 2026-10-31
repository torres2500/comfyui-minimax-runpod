# ComfyUI MiniMax H3 – RunPod template with model switches

Image: `ghcr.io/torres2500/comfyui-minimax-runpod:latest`

Each model has an environment variable. `1` = download, `0` = skip. Unset = `1`.
Set `HF_TOKEN` to avoid Hugging Face rate limits.

| Variable | Model |
|---|---|
| DL_VAE_VIDEO | minimax_h3_video_vae_fp16 |
| DL_VAE_AUDIO | minimax_h3_audio_vae_fp32 |
| DL_DIT_FL2VA_INT8 | minimax_h3_fl2va_pruned_int8_convrot |
| DL_DIT_SINGULARITY | Minimax-h3_Singularity_ref2va_Pruned_v1.3_int8 |
| DL_DIT_10EROS_MAX | 10Eros_Max_h3_hybrid_beta5_int8 |
| DL_TE_QWEN3VL_32B | qwen3vl_32b_heretic text encoder |
| DL_LORA_TURBO_8STEP | minimax_h3_fl2v_turbo_8step |
| DL_LORA_REF2V_TURBO_4STEP | minimax_h3_ref2v_turbo_4step |
| DL_LORA_TENSTRIP_TURBO | lightx2v_hybrid-4to8step-full-fusion_Turbo |
| DL_LORA_REALISM_PEOPLE | h3-realism-people |
| DL_LORA_CHARACTER_SWAP | h3_character_swap |
| DL_QWEN_IMAGE_DIT | qwen_image_2.1_int8_convrot |
| DL_QWEN_IMAGE_TE | qwen3-vl-8b-heretic text encoder |
| DL_QWEN_IMAGE_VAE | qwen_image_2.1_vae |
| DL_LORA_QWEN_DETAILER | elusarcas-qwen2-1-detailer |
| DL_LLM_GGUF | Defiant-Fable Q6_K |
| DL_LLM_MMPROJ | mmproj-BF16 |
| DL_TRT_RIFE | RIFE TensorRT engine (RTX PRO 6000 only) |
| DL_TRT_UPSCALER | 2xLexica TensorRT engine (RTX PRO 6000 only) |
| DL_UPSCALE_4X_ULTRASHARP | 4xUltrasharp |

`LIST_MODELS=1` prints what would download and exits.
