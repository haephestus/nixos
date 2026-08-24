# ---------------------------------------------------------------------------
# NVIDIA PRIME render offload
#
# The Intel UHD 630 iGPU drives the desktop (Hyprland runs on it); the
# GTX 1050 becomes compute/graphics-on-demand. This frees VRAM for CUDA
# inference whenever no external monitor is attached.
#
# Bus IDs verified against /sys on THIS machine (2026-08):
#   00:02.0 = Intel UHD 630   -> PCI:0:2:0
#   01:00.0 = NVIDIA GTX 1050 -> PCI:1:0:0
#
# External monitor caveat: the single physical HDMI port is wired to the
# NVIDIA GPU (card0-HDMI-A-2). While a monitor is attached the dGPU stays
# awake and display buffers share its VRAM — same situation as before this
# switch. Unplug it and runtime PM powers the card down again.
#
# OLLAMA_GPU_OVERHEAD in configuration.nix is deliberately KEPT: it protects
# docked sessions where display buffers land back in NVIDIA VRAM. Revisit
# only with nvidia-smi evidence from both docked and mobile states.
# ---------------------------------------------------------------------------

{ config, pkgs, ... }:

{
  nixpkgs.config = {
    allowUnfree = true;

    cudaSupport = true;
    cudaCapabilities = [ "6.1" ];
  };

  # Mesa for the iGPU that now renders the desktop.
  hardware.graphics.enable = true;

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    open = false;

    modesetting.enable = true;
    # Lets the card suspend when idle and wake for CUDA jobs.
    powerManagement.enable = true;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true; # provides the `nvidia-offload` wrapper
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Still list nvidia here; the iGPU uses the in-kernel modesetting driver.
  services.xserver.videoDrivers = [ "nvidia" ];

  boot.blacklistedKernelModules = [ "nouveau" ];
}
