{ config, pkgs, ... }:

{
  nixpkgs.config = {
    allowUnfree = true;

    cudaSupport = true;
    cudaCapabilities = [ "6.1" ];
  };

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    open = false;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  boot.blacklistedKernelModules = [ "nouveau" ];

}
