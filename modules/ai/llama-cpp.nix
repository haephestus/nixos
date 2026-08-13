# modules/ai/llama-cpp.nix
#
# llama.cpp with CUDA — the "tuning bench" alongside Ollama (see steward/docs/11).
# Serves an OpenAI-compatible /v1 API, so opencode/aider/Steward can point at it
# just like Ollama. Ollama stays your default; this is for dialed-in local coding
# and grammar-constrained tool output on the 3GB card.
{
  config,
  pkgs,
  ...
}:
let
  # CUDA build for the GTX 1050 (compute 6.1). If the override is heavy to build,
  # you can instead run llama.cpp from a devshell or fetch a prebuilt binary.
  llamaCudaPkg = pkgs.llama-cpp.override { cudaSupport = true; };
in
{
  environment.systemPackages = [ llamaCudaPkg ];

  # OPTIONAL: run llama-server as a user service on :8080 with a coder model.
  # Uncomment and set --model to a GGUF on your NVMe. Tune flags per docs/12.
  #
  # systemd.user.services.llama-server = {
  #   description = "llama.cpp OpenAI-compatible server (:8080)";
  #   wantedBy = [ "default.target" ];
  #   serviceConfig = {
  #     ExecStart = ''
  #       ${llamaCudaPkg}/bin/llama-server \
  #         --model %h/models/qwen2.5-coder-3b-instruct-q4_k_m.gguf \
  #         --n-gpu-layers 999 --ctx-size 8192 \
  #         --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn \
  #         --batch-size 512 --ubatch-size 128 --threads 4 \
  #         --host 127.0.0.1 --port 8080
  #     '';
  #     Restart = "on-failure";
  #   };
  # };
  #
  # Reminder: download GGUFs yourself (Hugging Face) onto the NVMe; llama.cpp has
  # no model registry. `--n-gpu-layers 999` tries to offload all; drop it until it
  # stops OOMing on the 3GB card (watch `nvidia-smi`).
}
