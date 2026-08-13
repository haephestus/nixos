# modules

Reusable NixOS and home-manager modules, grouped by area. Each subdirectory has
its own README. Modules marked **staged** are written but not wired into any
import — check the individual READMEs for status.

## Index

| Directory | Focus | Status |
|---|---|---|
| [ai/](ai/README.md) | opencode, Ollama/llama.cpp, inference tuning, coding agents | partially active |
| [containers/](containers/README.md) | docker (stub) | staged |
| [desktop/](desktop/README.md) | GNOME, NVIDIA (+ PRIME variant) | partially active |
| [devshells/](devshells/README.md) | standalone devshell flake (C/C++, Flutter, Java, Python, JS) | separate flake |
| [editors/](editors/README.md) | nvim (LazyVim + Neovide), JetBrains, VSCode | partially active |
| [security/](security/README.md) | sops-nix secrets | staged |
| [services/](services/README.md) | backups (litestream/restic), tailscale | staged |
| [terminal/](terminal/README.md) | ghostty, zellij, zsh, starship, direnv, alacritty | active |
| [tools/](tools/README.md) | nix-ld, ngrok | partially active |
| [virtualization/](virtualization/README.md) | distrobox / podman | active |

## Conventions

- Files are either **NixOS modules** (system-level, imported from
  `hosts/laptop/configuration.nix`) or **home-manager modules** (user-level,
  imported from `home-manager/home.nix`). The file headers usually say which.
- Many files are written as **documentation-first**: options are present but
  commented out with their type/default annotated (e.g. `ai/opencode.nix`,
  `editors/nvim/ide.nix`).
