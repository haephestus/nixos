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

    # Let the card power down when idle and wake for CUDA jobs.
    modesetting.enable = true;
    powerManagement.enable = true;

  };

  services.xserver.videoDrivers = [ "nvidia" ];

  boot.blacklistedKernelModules = [ "nouveau" ];

}
