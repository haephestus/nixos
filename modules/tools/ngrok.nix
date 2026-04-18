{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.ngrok
  ];

  services.ngrok = {
    enable = true;
    extraConfig = { };
    extraConfigFiles = [ ];
    tunnels = { };
  };
}
