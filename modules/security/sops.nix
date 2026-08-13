# modules/security/sops.nix
#
# Encrypted secrets via sops-nix (age). Secrets live ENCRYPTED in your config git
# repo (secrets/secrets.yaml); at activation, sops-nix decrypts them to
# root-only files under /run/secrets and hands the paths to the services that
# need them. Plaintext never lands in the world-readable Nix store.
#
# Prereqs (see steward/nix/README.md "Secrets"):
#   1. add sops-nix as a flake input + import its nixosModule
#   2. generate a host age key → /var/lib/sops-nix/key.txt
#   3. put your age *public* key in secrets/.sops.yaml
#   4. create + encrypt secrets/secrets.yaml  (sops secrets/secrets.yaml)
{
  config,
  ...
}:
{
  sops = {
    # Path to the ENCRYPTED file (adjust if you place it elsewhere in the repo).
    defaultSopsFile = ../../secrets/secrets.yaml;
    # Host key that can decrypt it. Generate once (see README).
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      # Whole env-files consumed by backups.nix `environmentFile` — the decrypted
      # path is pinned so backups.nix's /run/secrets/* references line up.
      "litestream" = { path = "/run/secrets/litestream"; };
      "restic-steward" = { path = "/run/secrets/restic-steward"; };

      # Single-value secrets, readable by your user (for shells / opencode).
      "openrouter_api_key" = { owner = "harbinger"; mode = "0400"; };
      "steward_token" = { owner = "harbinger"; mode = "0400"; };
    };
  };

  # Handy: expose the daemon token + cheap-API key to your interactive shell so
  # aider/opencode/the git hook pick them up. (Reads the decrypted files at login;
  # values still never touch the Nix store.)
  # environment.interactiveShellInit = ''
  #   [ -r ${config.sops.secrets."steward_token".path} ] && \
  #     export STEWARD_TOKEN="$(cat ${config.sops.secrets."steward_token".path})"
  #   [ -r ${config.sops.secrets."openrouter_api_key".path} ] && \
  #     export OPENROUTER_API_KEY="$(cat ${config.sops.secrets."openrouter_api_key".path})"
  # '';
}
