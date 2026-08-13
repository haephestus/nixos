# modules/desktop/nvidia-prime.nix
#
# ★ STAGED VARIANT of your existing modules/desktop/nvidia.nix ★
# This switches to NVIDIA PRIME *offload*: the Intel UHD 630 iGPU drives the
# desktop, the GTX 1050 becomes compute-only → the FULL ~3GB VRAM is free for
# inference (see steward/docs/12, Win #1). After applying, delete
# OLLAMA_GPU_OVERHEAD from configuration.nix and give models the freed VRAM.
#
# ⚠️ HIGHER RISK than the other staged modules — it changes the display stack.
#    * Verify the bus IDs on YOUR machine first (they're per-hardware):
#         lspci | grep -E "VGA|3D"
#      then convert e.g. "00:02.0" → "PCI:0:2:0", "01:00.0" → "PCI:1:0:0".
#    * Apply when you can reboot freely. If the GUI doesn't come up, pick the
#      PREVIOUS generation at the systemd-boot menu to roll back instantly.
#    * If you drive an EXTERNAL monitor over HDMI, it may be wired to the NVIDIA;
#      offload mode can complicate that. Internal-panel-only users are fine.
#
# To use: copy over modules/desktop/nvidia.nix (or import this instead), verify
# bus IDs, rebuild, reboot, then `nvidia-smi` to confirm CUDA still sees the card.
{
  config,
  pkgs,
  ...
}:
{
  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
    cudaCapabilities = [ "6.1" ];
  };

  # Needed for the iGPU to render the desktop (renamed from hardware.opengl).
  hardware.graphics.enable = true;

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    open = false;

    # Let the card power down when idle and wake for CUDA jobs.
    modesetting.enable = true;
    powerManagement.enable = true;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true; # provides the `nvidia-offload` wrapper
      intelBusId = "PCI:0:2:0"; # ← VERIFY with `lspci | grep -E "VGA|3D"`
      nvidiaBusId = "PCI:1:0:0"; # ← VERIFY
    };
  };

  # Still list nvidia here; the iGPU is handled by the default modesetting driver.
  services.xserver.videoDrivers = [ "nvidia" ];

  boot.blacklistedKernelModules = [ "nouveau" ];

  # After this works: remove `OLLAMA_GPU_OVERHEAD` from configuration.nix so
  # Ollama can use the whole 3GB. CUDA/Ollama use the discrete card automatically;
  # only *graphical* apps need `nvidia-offload` to run on it.
}
