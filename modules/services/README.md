# modules/services

System services (all currently staged).

| File | Type | Status | Purpose |
|---|---|---|---|
| `backups.nix` | NixOS | staged (intentionally inert) | Two-layer backups for `/var/lib/steward`: **litestream** (continuous SQLite replication to S3/R2) + **restic** (nightly encrypted snapshots, keep 7d/5w/12m). Disabled until bucket + credentials exist. |
| `tailscale.nix` | NixOS | staged (optional) | Tailscale mesh so a Flutter app can reach the Steward daemon without public exposure. |

## Status

Neither is imported by `hosts/laptop/configuration.nix` — both are ready to
wire in once the Steward daemon data path and credentials are set up.
