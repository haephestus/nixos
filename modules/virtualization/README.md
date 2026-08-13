# modules/virtualization

| File | Type | Status | Purpose |
|---|---|---|---|
| `distrobox.nix` | NixOS | **active** | Podman with Docker CLI compatibility (`virtualisation.podman.dockerCompat = true`) + the `distrobox` wrapper for mutable container distros. Imported by `hosts/laptop/configuration.nix`. |
