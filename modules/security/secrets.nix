{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ──────────────────────────────────────────
  # SOPS-NIX CONFIG (for ALL secrets)
  # ──────────────────────────────────────────
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      # User secrets
      "openrouter_api_key" = {
        owner = "harbinger";
        mode = "0400";
      };
      "steward_token" = {
        owner = "harbinger";
        mode = "0400";
      };
      "freellmapi_key" = {
        owner = "harbinger";
        mode = "0400";
      };
      "ollama_api_key" = {
        owner = "harbinger";
        mode = "0400";
      };

      # Service secrets
      "litestream" = {
        path = "/run/secrets/litestream";
      };
      "restic-steward" = {
        path = "/run/secrets/restic-steward";
      };
    };
  };

  # ──────────────────────────────────────────
  # ENVIRONMENT VARIABLES
  # ──────────────────────────────────────────
  environment.interactiveShellInit = ''
    [ -r ${config.sops.secrets."steward_token".path} ] && \
      export STEWARD_TOKEN="$(cat ${config.sops.secrets."steward_token".path})"
    [ -r ${config.sops.secrets."openrouter_api_key".path} ] && \
      export OPENROUTER_API_KEY="$(cat ${config.sops.secrets."openrouter_api_key".path})"
    [ -r ${config.sops.secrets."freellmapi_key".path} ] && \
      export FREELLMAPI_API_KEY="$(cat ${config.sops.secrets."freellmapi_key".path})"
    [ -r ${config.sops.secrets."ollama_api_key".path} ] && \
          export OLLAMA_API_KEY="$(cat ${config.sops.secrets."ollama_api_key".path})"
  '';
}
