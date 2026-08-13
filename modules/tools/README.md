# modules/tools

| File | Type | Status | Purpose |
|---|---|---|---|
| `nix-ld.nix` | NixOS | **active** | `programs.nix-ld.enable` with a broad curated library set (glibc, gcc, Java/Gradle, Flutter/Dart, X11/GL, OpenSSL, cairo/pango, FUSE, Neovim/LazyVim runtimes, …) so unpatched binaries run on NixOS. Imported by `hosts/laptop/configuration.nix`. |
| `ngrok.nix` | NixOS | staged | Installs ngrok + enables its systemd service (empty config). Not imported — the `ngrok` flake input is also commented out (stale entry remains in `flake.lock`). |
