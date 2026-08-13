# modules/ai

AI tooling and local-inference config.

| File | Type | Status | Purpose |
|---|---|---|---|
| `opencode.nix` | home-manager | **active** | Declarative opencode config via `programs.opencode` (model = local Ollama `ollama/qwen2.5-coder:3b`, tokyonight TUI theme). Full option tree documented/commented. |
| `coding-agents.nix` | NixOS | **active** | Installs `opencode` + `jq` system-wide (for Steward post-commit hooks). |
| `inference-tuning.nix` | NixOS | staged | CPU governor → `performance` + thermald, so local LLM inference doesn't throttle. |
| `llama-cpp.nix` | NixOS | staged | CUDA-enabled `llama.cpp` (OpenAI-compatible server) as a tuning bench alongside Ollama. |

## Strategy (from comments in the modules)

- **Local**: Ollama small model (private, light edits, Steward summaries) — the
  default model for opencode.
- **Cheap**: low-cost cloud APIs (OpenRouter/DeepSeek) for real work — opt-in,
  keys supplied via `opencode auth` / env vars, never in the Nix store.

## Notes

- API keys must **not** be committed — they'd land in the world-readable Nix store.
- `opencode.nix` is a home-manager module imported from `home-manager/home.nix`
  (see also the Neovim integration in `modules/editors/nvim/dotfiles/lua/plugins/opencode.lua`).
