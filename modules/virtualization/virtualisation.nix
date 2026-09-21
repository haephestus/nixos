{ pkgs, ... }:

{
  virtualisation = {
    docker = {
      enable = true;
    };
    podman = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    distrobox
    docker-compose
    openssl
  ];
}
