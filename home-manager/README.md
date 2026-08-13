# home-manager

User-level (per-`harbinger`) configuration. This is the entry point for the
standalone home-manager build; it aggregates the home-manager modules living in
`modules/` (terminal, editors, ai).

## Files

| File | Purpose |
|---|---|
| `home.nix` | The user-level config entry point |

## What `home.nix` does

- Sets `home.username = "harbinger"`, `home.homeDirectory = "/home/harbinger"`,
  `home.stateVersion = "25.05"`.
- Imports the user-facing modules:
  - `../modules/terminal/default.nix` — ghostty, zellij, zsh, starship, direnv
  - `../modules/editors/nvim/ide.nix` — Neovide
  - `../modules/editors/nvim/tui.nix` — LazyVim (uses the `lazyvim` special arg)
  - `../modules/editors/jetbrains.nix` — IntelliJ + shared `.ideavimrc`
  - `../modules/ai/opencode.nix` — opencode (TUI + config)
- Enables GNOME shell extensions via `dconf` (blur-my-shell, worksets).
- Runs the Megasync service (`services.megasync.enable = true`).
- Sets `EDITOR = "nvim"` and allows unfree packages.
- Manages itself (`programs.home-manager.enable = true`).

## Usage

```sh
# Standalone (as documented in the original config)
home-manager -f /etc/nixos/home-manager/home.nix switch

# Or via the flake (recommended once flake.nix eval is fixed)
home-manager switch --flake /etc/nixos#harbinger
```
