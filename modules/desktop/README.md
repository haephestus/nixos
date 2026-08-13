# modules/desktop

Desktop environment and GPU config.

| File | Type | Status | Purpose |
|---|---|---|---|
| `gnome.nix` | NixOS | **active** | GNOME desktop (X11 + GDM), keyboard layout `za`, trims default apps (cheese, eog, epiphany, geary, seahorse, …), enables blur-my-shell + open-bar extensions. |
| `nvidia.nix` | NixOS | **active** | Proprietary NVIDIA `legacy_580` driver for the GTX 1050 (CUDA cap 6.1), nouveau blacklisted, CUDA support on. Ollama/llama.cpp depend on this. |
| `nvidia-prime.nix` | NixOS | staged | PRIME *offload* variant: Intel iGPU drives the desktop, GTX 1050 reserved for CUDA inference. Header says to copy over `nvidia.nix` after verifying PCI bus IDs (marked `VERIFY`). |
| `default.nix` | — | stale | Empty placeholder, not imported. |

## Import wiring

- `gnome.nix` and `nvidia.nix` are imported by `hosts/laptop/configuration.nix`.
- `nvidia-prime.nix` is a documented, **not-yet-active** alternative to `nvidia.nix`.
