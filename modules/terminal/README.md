# modules/terminal

Terminal stack (home-manager modules). Imported via `default.nix`.

| File | Status | Purpose |
|---|---|---|
| `default.nix` | **active** | Import aggregator. Imports ghostty, zellij, zsh, starship, direnv. |
| `ghostty.nix` | **active** | Ghostty terminal: DepartureMono Nerd Font, size 12, TokyoNight Storm theme. |
| `zellij.nix` | **active** | Zellij multiplexer: Tokyo Night UI, simplified, no status bar / pane frames. |
| `zsh.nix` | **active** | zsh: completion, autosuggestions, syntax highlighting, history (2000, ignore dups), aliases (`vi=nvim`, `rebuild`, `upgrade`, `test-build`, `rehome`, `list-system`, `delete-system`, `garbage`), sources `scripts/os/clean.sh` + `scripts/devenv/devshells.sh`. |
| `starship.nix` | **active** | Starship prompt: TokyoNight-style format with c, cmake, rust, java, dart, nodejs, python modules. |
| `direnv.nix` | **active** | direnv + nix-direnv with zsh integration. |
| `alacritty.nix` | staged | Alacritty (FiraCode Nerd Font 12). Commented out in `default.nix` — Ghostty is the active terminal. |

## Caveats

- The zsh alias `find` in `zsh.nix` is malformed (contains a literal `$` inside
  the quoted string) — likely broken if used.
