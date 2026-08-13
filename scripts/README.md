# scripts

zsh helper library scripts, sourced from `modules/terminal/zsh.nix`
(`initContent`).

| File | Function | Purpose |
|---|---|---|
| `os/clean.sh` | `clean_up [gen...]` | Delete NixOS system generations by name via `nix-env --delete-generations`. |
| `devenv/devshells.sh` | `dev_env <shell>` | Drop into a devshell: `nix develop /etc/nixos/modules/devshells#<shell>`. |

## Caveats

- `devenv/devshells.sh` references an undefined `$dir` variable and never uses
  `prev_dir` — the `cd` into the intended directory is broken. Needs a fix to
  work as intended.
- Consider using `nix-sweep` (already in `environment.systemPackages`) for
  cleanup instead of hand-rolling `clean_up`.
