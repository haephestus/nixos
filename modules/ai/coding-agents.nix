# modules/ai/coding-agents.nix
#
# Phase 1 — private/cheap coding agents, system-wide.
#
#   * aider-chat : Python, git-native. Auto-commits each change with a
#                  descriptive message → perfect for the post-commit hook that
#                  feeds Steward's journal (see steward/docs/09). Definitely in
#                  nixpkgs.
#   * opencode   : TS/Bun agent with a headless `opencode serve` (REST + SSE on
#                  :4096) and a TS SDK — the seam Steward subscribes to for live
#                  progress WITHOUT forking. If `pkgs.opencode` is missing on
#                  your pin, see the fallback note at the bottom.
#
# jq + curl are here so the post-commit hook (steward/nix/hooks/post-commit) can
# POST commit metadata to the daemon.
#
# Model strategy (your GPU is ~3GB VRAM): run these against a *cheap API*
# (OpenRouter/DeepSeek) for real multi-file work; keep local Ollama (small
# models) for light/private edits. Provider config lives in home-manager
# (home-manager/opencode.nix), not here.
{
  config,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    jq
    opencode # ← if this errors on your pin, comment it out and use the bun fallback
    #aider-chat
  ];

  # OPTIONAL: run an always-on headless opencode server as a *user* service so
  # Steward always has an endpoint to talk to. Uncomment when you want it.
  # Auth: set OPENCODE_SERVER_PASSWORD via an env/secret, not inline.
  #
  # systemd.user.services.opencode-serve = {
  #   description = "opencode headless server (REST + SSE on :4096)";
  #   wantedBy = [ "default.target" ];
  #   serviceConfig = {
  #     ExecStart = "${pkgs.opencode}/bin/opencode serve --port 4096";
  #     Restart = "on-failure";
  #     # EnvironmentFile = "/run/secrets/opencode-server";  # OPENCODE_SERVER_PASSWORD=...
  #   };
  # };

  # ── Fallback if `pkgs.opencode` isn't packaged on your channel ──────────────
  # Remove `opencode` from systemPackages above and run it from your existing
  # bun devshell instead:
  #     nix develop /etc/nixos/modules/devshells#bun -c bunx opencode
  # or add opencode's flake as an input and reference its package here.
}
