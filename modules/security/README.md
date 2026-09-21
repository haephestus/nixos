# modules/security

| File | Type | Status | Purpose |
|---|---|---|---|
| `secrets.nix` | NixOS | ✅ Active | SOPS-nix encrypted secrets, decrypting to `/run/secrets` |

## Status

✅ SOPS-nix imported in `flake.nix`
✅ `secrets/secrets.yaml` created and encrypted
✅ Age key configured at `/var/lib/sops-nix/key.txt`

Secrets managed:
- `openrouter_api_key` - OpenRouter API key
- `steward_token` - Steward token
- `freellmapi_key` - FreeLLM API key
- `litestream` - Litestream configuration
- `restic-steward` - Restic steward configuration

## Usage

Edit secrets:
```bash
sops secrets/secrets.yaml
