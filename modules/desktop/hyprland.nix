# ---------------------------------------------------------------------------
# Hyprland desktop (system-level) — the only graphical session
#
# Dynamic tiling Wayland compositor. COSMIC has been removed; this module
# is now solely responsible for everything the COSMIC module used to
# provide implicitly.
#
# What programs.hyprland does for you automatically:
#   - Installs Hyprland and registers the Wayland session with greetd
#   - Pulls in xdg-desktop-portal-hyprland (screenshare / screenshots)
#   - Enables the xdg-desktop-portal service
#
# NVIDIA notes:
#   - The compositor renders on the Intel iGPU (AQ_DRM_DEVICES, set in
#     home-manager/hyprland.nix). No GLX/GBM vendor env vars are needed for
#     Hyprland itself to start; add __GLX_VENDOR_LIBRARY_NAME etc. only if/
#     when launching apps on the dGPU via nvidia-offload.
#   - hardware.nvidia.modesetting.enable is already set in nvidia.nix —
#     do not duplicate it here.
#   - This card runs the legacy_580 proprietary driver (open = false).
#     If the session fails to start or artifacts appear, first suspect
#     the driver, not Hyprland itself. Roll back from systemd-boot's
#     previous generation if needed.
# ---------------------------------------------------------------------------

{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # GTK portal for file pickers / fallback where the hyprland portal
  # doesn't cover a desktop interface.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  environment.systemPackages = with pkgs; [
    # NOTE: hyprpolkitagent is intentionally NOT here — home-manager owns it
    # (systemd user service in home-manager/hyprland.nix). Adding it here too
    # just ships a dead second copy.
    libva-utils
  ];

  # Native Wayland for Electron/Chromium apps instead of XWayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Intel UHD 630 (Coffee Lake) video decode via VAAPI. With the iGPU
  # rendering the desktop, hardware video acceleration now goes through
  # intel-media-driver (iHD), not the NVIDIA card. libva-utils provides
  # `vainfo` to verify.
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    libvdpau-va-gl
  ];

  # ==========================================================================
  # Display manager: greetd + ReGreet
  # ==========================================================================
  # greetd itself is desktop-agnostic: it starts whatever session the user
  # picks at login (any registered wayland-sessions/*.desktop or
  # xsessions/*.desktop entry). Adding another DE later makes it appear in
  # the picker automatically.
  #
  # History: tuigreet was tried first (--remember* flags crash when
  # /var/cache/tuigreet is missing, apognu/tuigreet#33). ReGreet replaced it.
  #
  # Hosting ReGreet inside a throwaway Hyprland instance (instead of the
  # module-default cage kiosk compositor) was also attempted; the greeter's
  # Hyprland crashed in initServer ("backend failed") on this machine and is
  # parked until the desktop itself is stable. To revisit:
  #   services.greetd.settings.default_session.command =
  #     "${pkgs.dbus}/bin/dbus-run-session ${config.programs.hyprland.package}/bin/Hyprland -c /etc/greetd/hyprland-greeter.conf";
  # plus an environment.etc."greetd/hyprland-greeter.conf" (see git history).
  #
  # Only ONE display manager may claim display-manager.service.
  services.displayManager.regreet = {
    enable = true;

    # Minimal dark greeter — matches the waybar palette (see
    # home-manager/hyprland.nix). Adwaita-dark handles buttons/inputs;
    # extraCss only repaints the bare white page background.
    theme.name = "Adwaita-dark";
    font = {
      package = pkgs.nerd-fonts.fira-code;
      name = "FiraCode Nerd Font";
      size = 13;
    };
    settings.GTK.application_prefer_dark_theme = true;
    extraCss = ''
      window {
        background-color: #1e1e2e;
        color: #cdd6f4;
      }
    '';

    # To use a wallpaper instead of the flat color, once one exists:
    #   settings.background.path = ./path/to/wallpaper;  (or an /abs/path)
    #   settings.background.fit = "Cover";
  };

  services.greetd.enable = true;

  # Register Hyprland's .desktop session file into the system profile.
  # Without this, wayland-sessions is empty and ReGreet shows NO sessions
  # to launch — SDDM/GDM modules add this path themselves, greetd+ReGreet
  # does not.
  environment.pathsToLink = [ "/share/wayland-sessions" ];

  # Colon-free stable GPU node names for AQ_DRM_DEVICES.
  # Aquamarine splits AQ_DRM_DEVICES on ':' — which collides with PCI
  # bus IDs, so /dev/dri/by-path/pci-0000:XX:YY.Z-card CANNOT be used
  # directly (it shatters into garbage paths → "Found no gpus to use";
  # confirmed by hyprlandCrashReport1609.txt, 2026-08-24). Raw /dev/dri/cardN
  # numbering is not boot-stable. These udev symlinks give stable names with
  # no colons; referenced from home-manager/hyprland.nix.
  #
  # udev rules (not tmpfiles `L!`): symlinks appear atomically the moment the
  # card enumerates and vanish if it does — no boot-order race between
  # tmpfiles-setup and udev settling. DEVPATH globs match the card nodes
  # under each GPU's PCI slot regardless of which cardN number they get.
  # NOTE: the GTX 1050 sits behind a PCIe bridge, so its sysfs path is
  # /devices/pci0000:00/0000:00:01.0/0000:01:00.0/drm/cardN — hence the
  # extra '*' before the device address in its DEVPATH glob.
  services.udev.extraRules = ''
    KERNEL=="card[0-9]*", SUBSYSTEM=="drm", DEVPATH=="*/0000:00:02.0/drm/*", SYMLINK+="dri-gpu-intel"
    KERNEL=="card[0-9]*", SUBSYSTEM=="drm", DEVPATH=="*/0000:01:00.0/drm/*", SYMLINK+="dri-gpu-nvidia"
  '';

  # ==========================================================================
  # Formerly-implicit COSMIC services — must be owned explicitly now
  # ==========================================================================

  # Bluetooth was enabled as a COSMIC default; keep it working.
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Power profiles daemon — this is a laptop; without it there is no
  # performance/balanced/power-saver switching.
  services.power-profiles-daemon.enable = true;

  # dconf backend for GTK apps storing settings.
  programs.dconf.enable = true;

  # XDG user directory management (Documents/Downloads/...).
  xdg.portal.enable = true;
}
