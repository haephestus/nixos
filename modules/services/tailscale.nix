# modules/services/tailscale.nix  (optional)
#
# Always-on private mesh so your Steward Flutter app (phone/laptop) can reach the
# home daemon with NO public surface — the daemon stays on your hardware for
# local Ollama; only devices on your tailnet can see it. Better than ngrok for
# the daily driver (ngrok stays useful for ad-hoc shares).
#
# After rebuild, run once:  sudo tailscale up
# Then point the app at the daemon's tailscale IP (100.x.y.z) or MagicDNS name.
{
  config,
  pkgs,
  ...
}:
{
  services.tailscale.enable = true;

  # If you later expose the daemon only over tailscale, you can firewall its port
  # to the tailscale interface. Leave commented until the daemon exists:
  # networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8000 ];
}
