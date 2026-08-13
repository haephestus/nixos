# NixOS Configuration

Declarative config for the `harbinger` machine — NixOS system + standalone home-manager,
with flake-based builds. This is the living documentation of the whole repo.

## Quick reference

```sh
# Rebuild the system
sudo nixos-rebuild switch --flake .#harbinger

# Rebuild user config (standalone home-manager)
home-manager -f ./home-manager/home.nix switch

# Rebuild user config via the flake
home-manager switch --flake .#harbinger

# Enter a devshell (see modules/devshells)
nix develop /etc/nixos/modules/devshells#<shell-name>
```

## Store cleanup (nix-sweep)

`nix-sweep` (installed on this machine) trims old profile generations and garbage-collects
the Nix store. `cleanout` removes old generations; `gc` (or `cleanout --gc`) frees the
unreferenced store paths.

> ⚠️ `--remove-older` / `--keep-newer` take a **suffixed** duration (`30d`, `14d`, `6h`).
> A bare number is parsed as **seconds** — `--remove-older 30` deletes everything but the
> newest/active generation.

```sh
# See what would be removed (dry run)
nix-sweep cleanout -d system user home --keep-min 1 --remove-older 30d --gc

# Clean: drop generations older than 30 days, keep the newest per profile, then GC
nix-sweep cleanout system user home --keep-min 1 --remove-older 30d --gc

# Same, non-interactive, GC only if store > 100 GiB (safe to script)
nix-sweep cleanout -n system user home --keep-min 1 --remove-older 30d --gc --gc-bigger 100

# More aggressive: keep 2 generations, drop anything older than 14 days
nix-sweep cleanout -n system user home --keep-min 2 --remove-older 14d --gc --gc-bigger 100

# Garbage collection alone
nix-sweep gc              # ask before running
nix-sweep gc -n -b 100    # non-interactive, only if store > 100 GiB
nix-sweep gc -n -q 80     # only if device is > 80% full
nix-sweep gc -d           # dry run

# Dedupe identical store paths (hardlinks) — frees space without deleting anything
nix-store --optimise

# Inspect store / profile usage before and after
nix-sweep analyze
```

The newest and currently-active generation of each profile is never removed.

### Automatic cleanup (systemd timer)

`modules/services/nix-sweep.nix` runs the 30-day cleanup automatically every week
(`systemctl list-timers nix-sweep`). Logs: `journalctl -u nix-sweep.service`.

`nix.settings.auto-optimise-store = true` (in `hosts/laptop/configuration.nix`) dedupes
identical store files after every build, so the store stays lean without manual runs.

## Layout

```
/etc/nixos
├── flake.nix                     # entry point: NixOS host + home-manager config
├── flake.lock
├── hosts/
│   └── laptop/                   # the `harbinger` host (system-level config)
├── home-manager/
│   └── home.nix                  # user-level entry point
├── modules/
│   ├── ai/                       # opencode, ollama/llama.cpp, tuning, agents
│   ├── containers/               # docker (stub)
│   ├── desktop/                  # gnome, nvidia (+ prime variant)
│   ├── devshells/                # standalone devshell flake + per-language shells
│   ├── editors/                  # nvim (lazyvim + neovide), jetbrains, vscode
│   ├── security/                 # sops-nix (secrets)
│   ├── services/                 # backups (litestream/restic), tailscale
│   ├── terminal/                 # ghostty, zellij, zsh, starship, direnv, alacritty
│   ├── tools/                    # nix-ld, ngrok
│   └── virtualization/           # distrobox / podman
├── scripts/
│   ├── os/clean.sh               # zsh function: delete system generations
│   └── devenv/devshells.sh       # zsh function: `dev_env <shell>`
└── README.md
```

## How it fits together

- **`flake.nix`** exposes two configurations:
  - `nixosConfigurations.harbinger` → imports `hosts/laptop/configuration.nix` (system-wide: desktop, NVIDIA, Ollama, nix-ld, distrobox, coding agents).
  - `homeConfigurations.harbinger` → imports `home-manager/home.nix` (user-level: terminal, nvim, jetbrains, opencode), plus the `lazyvim` module as a special arg.
- **`home-manager/home.nix`** aggregates the home-manager modules in `modules/` (terminal, editors, ai).
- **`modules/devshells/`** is a *separate, standalone* flake — run with `nix develop` / `nix run`, not part of the main flake.

## Per-directory docs

- [hosts/](hosts/README.md) — the laptop host
- [home-manager/](home-manager/README.md) — user-level config
- [modules/](modules/README.md) — module index (each group has its own README)
- [scripts/](scripts/README.md) — shell helper scripts

## Status notes

Some modules are intentionally **staged** (written but not wired into any import).
See the per-directory READMEs for exactly what is active vs. staged. Notable items:

- Staged/optional: `nvidia-prime.nix`, `inference-tuning.nix`, `llama-cpp.nix`,
  `sops.nix`, `backups.nix`, `tailscale.nix`, `ngrok.nix`, `vscode.nix`, `docker.nix`.
- Secrets: the Weylus hotspot PSK is hardcoded in `hosts/laptop/configuration.nix`
  (`somepassword123`) — a candidate to move into sops once `security/sops.nix` is enabled.
- Store cleanup: see [Store cleanup](#store-cleanup-nix-sweep) above — keep the `nixpkgs`
  input ref in `flake.nix`/`flake.lock` in sync (`nixos-unstable`, not `unstable`), or the
  flake can't re-resolve its lock.
