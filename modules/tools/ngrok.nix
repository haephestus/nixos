{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  services.ngrok = {
    enable = true;
    extraConfig = { };
    extraConfigFiles = [
      # reference to files containing `authtoken` and `api_key` secrets
      # ngrok will merge these, together with `extraConfig`
    ];
    tunnels = {
      # ...
    };
  };
}
