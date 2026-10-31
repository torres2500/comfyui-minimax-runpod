#!/bin/bash
BASE_DIR="/workspace/runpod-slim/ComfyUI/models"
LOG="/var/log/minimax-h3-models.log"
READY_MARKER="/workspace/runpod-slim/ComfyUI/main.py"

pip install --no-cache-dir -q "hf-transfer" "huggingface_hub" 2>/dev/null
export HF_HUB_ENABLE_HF_TRANSFER=1
export HF_XET_HIGH_PERFORMANCE=1

# Models: subdir|name|url|min_size_bytes (min_size = sanity check)
MODELS=(
    "vae|minimax_h3_video_vae_fp16.safetensors|https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_fp16.safetensors|5200000000|DL_VAE_VIDEO"
    "vae|minimax_h3_audio_vae_fp32.safetensors|https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors|600000000|DL_VAE_AUDIO"
    # ── Tiny H3 VAE (taeh3) is baked into the image — no runtime download ──
    # ── Pure INT8 ConvRot DiT (Comfy-Org official) — better quality than NVFP4 hybrid ──
    "diffusion_models|minimax_h3_fl2va_pruned_int8_convrot.safetensors|https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors|20000000000|DL_DIT_FL2VA_INT8"
    # ── Singularity fusion (T2V/I2V/R2V/V2V) — sostituisce ref2va nativo ──
    "diffusion_models|Minimax-h3_Singularity_ref2va_Pruned_v1.3_int8.safetensors|https://huggingface.co/WarmBloodAban/Minimax-h3_Singularity/resolve/main/Minimax-h3_Singularity_ref2va_Pruned_v1.3_int8.safetensors|20000000000|DL_DIT_SINGULARITY"
    # ── Full H3 conditioning TE: Ultra Heretic INT8 ConvRot (uncensored, ethanfel) ──
    "text_encoders|qwen3vl_32b_heretic_minimax_h3_nvfp4.safetensors|https://huggingface.co/Momoking/Qwen3-VL-32B-Heretic-MiniMax-H3-NVFP4/resolve/main/qwen3vl_32b_heretic_minimax_h3_nvfp4.safetensors|15000000000|DL_TE_QWEN3VL_32B"
    # ── lightx2v Turbo LoRA 8-step 768p (Apache-2.0, trained at 1344×768) — no custom node needed ──
    "loras|minimax_h3_fl2v_turbo_8step_v1.0_768p_comfyui_bf16.safetensors|https://huggingface.co/lightx2v/Minimax-h3-Turbo/resolve/main/minimax_h3_fl2v_turbo_8step_v1.0_768p_comfyui_bf16.safetensors|1950000000|DL_LORA_TURBO_8STEP"
    "loras|minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors|https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors|1950000000|DL_LORA_REF2V_TURBO_4STEP"
    # ── fal Realism People LoRA (trigger: r34l1sm) ──
    "loras|h3-realism-people-t2v-i2v-r2v.safetensors|https://huggingface.co/fal/MiniMax-H3-Realism-People-LoRA/resolve/main/h3-realism-people-t2v-i2v-r2v.safetensors|100000000|DL_LORA_REALISM_PEOPLE"
    # ── akatz Character-Swap LoRA — ref2v character swap ──
    "loras|h3_character_swap_pro4500_1000.safetensors|https://huggingface.co/akatz-ai/MiniMax-H3-Character-Swap-LoRA/resolve/main/h3_character_swap_pro4500_1000.safetensors|150000000|DL_LORA_CHARACTER_SWAP"
    # ── TenStrip combined turbo LoRA (4.4GB) — the exact delta fused into the TURBO checkpoint; use with 10Eros non-turbo ──
    "loras|lightx2v_hybrid-4to8step-full-fusion_Turbo_pruned.safetensors|https://huggingface.co/TenStrip/MinimaxH3-Turbo_Shenanigans/resolve/main/lightx2v_hybrid-4to8step-full-fusion_Turbo_pruned.safetensors|4300000000|DL_LORA_TENSTRIP_TURBO"
    # ── 10Eros-Max Hybrid Beta5 INT8 NON-turbo (TenStrip, 21GB) — turbo via LoRA esterno regolabile (no color shift baked-in) ──
    "diffusion_models|10Eros_Max_h3_hybrid_beta5_int8.safetensors|https://huggingface.co/TenStrip/10Eros-Max/resolve/main/10Eros_Max_h3_hybrid_beta5_int8.safetensors|20000000000|DL_DIT_10EROS_MAX"
    # ── Qwen Image 2.1 (storyboard Stage1) ──
    "diffusion_models|qwen_image_2.1_int8_convrot.safetensors|https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/diffusion_models/qwen_image_2.1_int8_convrot.safetensors|7200000000|DL_QWEN_IMAGE_DIT"
    "text_encoders|qwen3-vl-8b-heretic-1.3.0-int8convrot.safetensors|https://huggingface.co/craftingmod/Qwen3-VL-8B-Heretic-INT8/resolve/main/qwen3-vl-8b-heretic-1.3.0-int8convrot.safetensors|10900000000|DL_QWEN_IMAGE_TE"
    "vae|qwen_image_2.1_vae_bf16.safetensors|https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/vae/qwen_image_2.1_vae_bf16.safetensors|670000000|DL_QWEN_IMAGE_VAE"
    "loras|elusarcas-qwen2-1-detailer-v1.safetensors|https://huggingface.co/reverentelusarca/elusarcas-qwen-2.1-detail-enhancer-lora/resolve/main/elusarcas-qwen2-1-detailer-v1.safetensors|79000000|DL_LORA_QWEN_DETAILER"
    # ── QwenVL-Mod enhancer LLM: Defiant-Fable NEO-MAX Q6_K + mmproj ──
    "LLM/GGUF|Qwen3.5-9B-The-Defiant-Fable-Uncnr-Heretic-NEO-MAX-Q6_K.gguf|https://huggingface.co/DavidAU/Qwen3.5-9B-The-Defiant-Fable-Uncensored-Heretic-NEO-IMATRIX-MAX-MTP-GGUF/resolve/main/Qwen3.5-9B-The-Defiant-Fable-Uncnr-Heretic-NEO-MAX-Q6_K.gguf|8559000000|DL_LLM_GGUF"
    "LLM/GGUF|mmproj-BF16.gguf|https://huggingface.co/DavidAU/Qwen3.5-9B-The-Defiant-Fable-Uncensored-Heretic-NEO-IMATRIX-MAX-MTP-GGUF/resolve/main/mmproj-BF16.gguf|900000000|DL_LLM_MMPROJ"
    # ── Prebuilt TensorRT engines (RTX PRO 6000, TRT 10.15.1.29) — skips ~1min compile at first use ──
    "tensorrt/rife|rife425_ensemble_False_scale_1_sim_fp16_large_1x3x720x720_1x3x1440x1440_1x3x1920x1920_10.15.1.29.trt|https://huggingface.co/huchukato/garage/resolve/main/tensorrt/rife/rife425_ensemble_False_scale_1_sim_fp16_large_1x3x720x720_1x3x1440x1440_1x3x1920x1920_10.15.1.29.trt|40000000|DL_TRT_RIFE"
    "tensorrt/upscaler|2xLexicaRRDBNet_fp16_1x3x256x256_2x3x512x512_2x3x2048x2048_10.15.1.29.trt|https://huggingface.co/huchukato/garage/resolve/main/tensorrt/upscaler/2xLexicaRRDBNet_fp16_1x3x256x256_2x3x512x512_2x3x2048x2048_10.15.1.29.trt|30000000|DL_TRT_UPSCALER"
    "upscale_models|4xUltrasharp_4xUltrasharpV10.pth|https://huggingface.co/huchukato/garage/resolve/main/upscale_models/4xUltrasharp_4xUltrasharpV10.pth|63000000|DL_UPSCALE_4X_ULTRASHARP"
)


# ── Model selection: every model has its own env variable (see last field of each entry) ──
#   Set it to 1 = download, 0 = skip.  Unset = 1 (download), so default behaviour is unchanged.
#   Example (RunPod template env vars):  DL_DIT_10EROS_MAX=0   DL_TRT_RIFE=0
#   LIST_MODELS=1 prints what WOULD download (after applying your 0/1 values) and exits.
_FILTERED=()
for e in "${MODELS[@]}"; do
    _var="${e##*|}"
    _val="${!_var:-1}"
    _val="${_val//[[:space:]]/}"
    if [ "$_val" = "0" ]; then continue; fi
    _FILTERED+=("$e")
done
MODELS=("${_FILTERED[@]}")

if [ "${LIST_MODELS:-0}" = "1" ]; then   # dry run: print what WOULD download, then exit
    i=0; for e in "${MODELS[@]}"; do i=$((i+1)); echo "$i) ${e%%|*}/$(echo "$e" | cut -d'|' -f2)"; done
    exit 0
fi

log() { echo "$(date): $*" | tee -a "$LOG"; }

TOTAL_MODELS=${#MODELS[@]}
CURRENT=0

log "📥 === MiniMax H3 model download started (PID $$) — $TOTAL_MODELS models ==="
log "⏳ Waiting for /workspace mount and ComfyUI ready marker..."
for i in $(seq 1 120); do
    [ -f "$READY_MARKER" ] && break
    sleep 5
done

if [ ! -f "$READY_MARKER" ]; then
    log "❌ ERROR: ComfyUI ready marker not found after 600s, aborting"
    exit 1
fi

log "✅ ComfyUI ready, base dir: $BASE_DIR"
mkdir -p "$BASE_DIR"/{vae,vae_approx,diffusion_models,text_encoders,loras,checkpoints}

# MODEL_VOLUME_PATH: external model storage (network volume at /workspace/storage,
# global volume at /workspace-global, or any mounted path). When set, we symlink
# its subdirs into models/ and write extra_model_paths.yaml — no downloads needed.
# Auto-detect common mount points when the env var is not set.
if [ -z "${MODEL_VOLUME_PATH:-}" ]; then
    for cand in /workspace/storage/models /workspace/models /workspace-global/models /workspace-global /workspace/storage; do
        if [ -d "$cand/diffusion_models" ] || [ -d "$cand/vae" ]; then
            MODEL_VOLUME_PATH="$cand"
            log "🔎 Auto-detected model volume at $MODEL_VOLUME_PATH"
            break
        fi
    done
fi
if [ -n "${MODEL_VOLUME_PATH:-}" ] && [ -d "$MODEL_VOLUME_PATH" ]; then
    log "🔗 MODEL_VOLUME_PATH=$MODEL_VOLUME_PATH — linking models, skipping downloads"
    for d in "$MODEL_VOLUME_PATH"/*/; do
        [ -d "$d" ] || continue
        dest="$BASE_DIR/$(basename "$d")"
        rmdir "$dest" 2>/dev/null  # succeeds only if empty
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            log "   ⚠️ $dest non-empty dir, not linking"
            continue
        fi
        ln -sfn "$d" "$dest"
        log "   ↪ $(basename "$d") -> $d"
    done
    cat > "$(dirname "$BASE_DIR")/extra_model_paths.yaml" <<YAML
shared_volume:
  base_path: $MODEL_VOLUME_PATH
  diffusion_models: diffusion_models
  text_encoders: text_encoders
  loras: loras
  vae: vae
  vae_approx: vae_approx
  ultralytics: ultralytics
  sams: sams
  LLM: LLM/GGUF
  checkpoints: checkpoints
YAML
    log "🏁 extra_model_paths.yaml written — volume models ready"
    exit 0
fi

# Polls the temp dir size while hf/hf_transfer downloads (hf_transfer emits no
# parseable progress when detached), logging a bar + % + MB every 20s.
monitor_progress() {
    local watch_dir="$1" expected="$2" name="$3"
    local cur pct filled pad bar exp_mb
    exp_mb=$(( expected / 1048576 ))
    while :; do
        cur=$(du -sb "$watch_dir" 2>/dev/null | awk '{print $1}')
        cur=${cur:-0}
        pct=$(( cur * 100 / expected ))
        [ "$pct" -gt 100 ] && pct=100
        filled=$(( pct / 5 ))
        printf -v bar '%*s' "$filled" ''; bar=${bar// /#}
        printf -v pad '%*s' "$((20 - filled))" ''; pad=${pad// /-}
        log "   ⏳ $name [${bar}${pad}] ${pct}% ($((cur / 1048576))/${exp_mb} MB)"
        sleep 20
    done
}

download_model() {
    local subdir="$1" name="$2" url="$3" min_size="$4"
    local dest="$BASE_DIR/$subdir/$name"
    local max_retries=5

    local repo_id repo_path
    repo_id=$(echo "$url" | awk -F/ '{print $4"/"$5}')
    repo_path=$(echo "$url" | sed -E 's#https?://[^/]+/[^/]+/[^/]+/resolve/main/(.+)#\1#')

    local hf_cmd="hf"
    command -v hf >/dev/null 2>&1 || hf_cmd="huggingface-cli"

    for attempt in $(seq 1 $max_retries); do
        if [ -f "$dest" ] || [ -L "$dest" ]; then
            local size
            size=$(stat -L -c%s "$dest" 2>/dev/null || stat -L -f%z "$dest" 2>/dev/null || echo 0)
            if [ "$size" -ge "$min_size" ]; then
                log "✅ $name already present ($size bytes >= $min_size), skipping"
                return 0
            else
                log "⚠️  $name incomplete ($size bytes < $min_size), retrying (attempt $attempt/$max_retries)"
            fi
        else
            log "📥 Downloading $name (attempt $attempt/$max_retries)..."
        fi

        local tmp_dir="$BASE_DIR/.tmp_download_${name//\//_}"
        rm -rf "$tmp_dir"
        mkdir -p "$tmp_dir" "$(dirname "$dest")"
        export HF_HUB_ENABLE_HF_TRANSFER=1
        export HF_XET_HIGH_PERFORMANCE=1
        local resume_flag=""
        [ "$hf_cmd" = "huggingface-cli" ] && resume_flag="--resume-download"

        monitor_progress "$tmp_dir" "$min_size" "$name" &
        local mon_pid=$!

        if timeout 900 $hf_cmd download "$repo_id" "$repo_path" \
                --local-dir "$tmp_dir" \
                $resume_flag 2>&1 | tee -a "$LOG"; then
            kill "$mon_pid" 2>/dev/null; wait "$mon_pid" 2>/dev/null
            local downloaded_path="$tmp_dir/$repo_path"
            if [ -f "$downloaded_path" ] || [ -L "$downloaded_path" ]; then
                if [ -L "$downloaded_path" ]; then
                    ln -sf "$(readlink -f "$downloaded_path")" "$dest"
                else
                    mv -f "$downloaded_path" "$dest"
                fi
                rm -rf "$tmp_dir"
                local size
                size=$(stat -L -c%s "$dest" 2>/dev/null || stat -L -f%z "$dest" 2>/dev/null || echo 0)
                if [ "$size" -ge "$min_size" ]; then
                    log "✅ $name downloaded successfully ($size bytes)"
                    return 0
                else
                    log "⚠️  $name downloaded but size $size < $min_size, will retry"
                fi
            else
                log "⚠️  $name not found at $downloaded_path after download, will retry"
                rm -rf "$tmp_dir"
            fi
        else
            kill "$mon_pid" 2>/dev/null; wait "$mon_pid" 2>/dev/null
            log "⚠️  $hf_cmd failed for $name (attempt $attempt), retrying in $((attempt*10))s..."
            rm -rf "$tmp_dir"
        fi

        [ "$attempt" -lt "$max_retries" ] && sleep $((attempt * 30))
    done

    log "❌ FAILED: $name could not be downloaded after $max_retries attempts"
    return 1
}

failures=0
MODEL_IDX=0
for entry in "${MODELS[@]}"; do
    MODEL_IDX=$((MODEL_IDX + 1))
    IFS='|' read -r subdir name url min_size _var <<< "$entry"
    log "━━━ [$MODEL_IDX/$TOTAL_MODELS] ━━━"
    download_model "$subdir" "$name" "$url" "$min_size" || failures=$((failures + 1))
    sleep 5
done

log "📦 === MiniMax H3 model download finished ($failures failures) ==="
log "✅ All models ready — ComfyUI can now use MiniMax H3 workflows"
