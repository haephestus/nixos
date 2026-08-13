# modules/editors

Editor configuration.

| File | Type | Status | Purpose |
|---|---|---|---|
| `nvim/tui.nix` | home-manager | **active** | LazyVim via `programs.lazyvim`: `configFiles = ./dotfiles`, language extras (nix, python, html, jinja, typescript, java, kotlin, dart), formatter/LSP packages. |
| `nvim/ide.nix` | home-manager | **active** | Neovide (GUI Neovim client). Full `programs.neovide` option tree documented/commented. |
| `nvim/dotfiles/` | — | **active** | LazyVim starter config (lazy.nvim bootstrap, `lua/plugins/*`, `lazy-lock.json` pinning ~58 plugins). |
| `jetbrains.nix` | home-manager | **active** | IntelliJ IDEA Community + a shared `~/.config/nvim/shared.vim` (vimscript consumed by both Neovim and IdeaVim) and a full `.ideavimrc` with IDE-action keymaps. |
| `vscode.nix` | home-manager | staged | Minimal `programs.vscode.enable = true` stub. Not imported. |

## Neovim plugins (`nvim/dotfiles/lua/plugins/`)

conform (formatters), flutter-tools, iron (REPLs), java (Minecraft/Gradle/jdtls),
leetcode, opencode, outline, rainbow-delimiters, snippets (LuaSnip + friendly),
surround (`sorround.lua` — filename typo), sql (dadbod), todo-comments,
todo-md, twilight. `example.lua` is an inert commented sample.

## Wiring

- `home-manager/home.nix` imports `nvim/ide.nix`, `nvim/tui.nix`, and `jetbrains.nix`.
- `nvim/tui.nix` uses the `lazyvim` special arg passed from `flake.nix`.
