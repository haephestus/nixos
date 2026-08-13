# modules/security

| File | Type | Status | Purpose |
|---|---|---|---|
| `sops.nix` | NixOS | staged | sops-nix encrypted secrets (age), decrypting to `/run/secrets` at activation. References `../../secrets/secrets.yaml` (doesn't exist yet). |

## Status

Not imported. Prerequisites not yet done in `flake.nix`:

1. Add `sops-nix` as a flake input.
2. Create `secrets/secrets.yaml`.
3. Configure the age key at `/var/lib/sops-nix/key.txt`.

Intended secrets (from comments): `litestream`, `restic-steward`,
`openrouter_api_key`, `steward_token`. A good target for the hardcoded Weylus
hotspot PSK in `hosts/laptop/configuration.nix`.
