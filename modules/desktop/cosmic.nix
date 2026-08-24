# ---------------------------------------------------------------------------
# COSMIC Desktop Environment
#
# System76's Rust-based Wayland compositor + desktop shell.
#
# BARE MINIMUM TO RUN:
#   services.desktopManager.cosmic.enable = true;
#   services.displayManager.cosmic-greeter.enable = true;   # login screen
#
# What the module does for you automatically (do NOT re-enable these
# manually unless you have a reason):
#   - Installs the core COSMIC packages (comp, panel, files, settings,
#     launcher, term, applets, session, greeter, etc.)
#   - Registers the COSMIC Wayland session in services.displayManager.sessionPackages
#   - Enables XDG portal + xdg-desktop-portal-cosmic (file pickers/screenshare)
#   - Enables dconf, polkit (with pkexec), rtkit, libinput, upower,
#     accounts-daemon, geoclue2, gvfs, gnome-keyring, pipewire bits
#   - Installs default fonts (Fira, Noto, Open Sans) and icon/sound themes
#   - Sensible defaults: bluetooth, networkmanager, avahi, acpid,
#     power-profiles-daemon (unless system76 power daemon is in use)
#
# NOTES:
#   - COSMIC is Wayland-only. services.xserver.enable is NOT required.
#   - Do NOT enable a second display manager alongside cosmic-greeter.
#     Both GDM and greetd claim the display-manager.service alias and
#     will fight. Pick ONE:
#       * cosmic-greeter (recommended for a self-contained COSMIC setup)
#       * GDM (if you keep gnome.nix / other DEs) — then leave the
#         cosmic-greeter block commented out; COSMIC still shows up in
#         the GDM session list.
#   - NVIDIA: COSMIC needs modesetting on for NVIDIA Wayland
#     (hardware.nvidia.modesetting.enable = true — already set in
#     ../nvidia.nix). XWayland is on by default for legacy apps.
# ---------------------------------------------------------------------------

{ config, pkgs, ... }:

{
  # ==========================================================================
  # REQUIRED — bare minimum for a running COSMIC desktop
  # ==========================================================================

  # Enable the COSMIC desktop environment (compositor, panel, settings, etc.)
  services.desktopManager.cosmic.enable = true;

  # Enable the COSMIC login greeter (the lock-screen-style login screen).
  # This is a greetd-based display manager; skip it only if you use GDM/SDDM.
  services.displayManager.cosmic-greeter.enable = true;

  # ==========================================================================
  # OPTIONAL — all available options, documented and commented out
  # ==========================================================================

  # --- XWayland support -----------------------------------------------------
  # Run legacy X11 apps under COSMIC. Disable only if you know you don't
  # need any X11 application. When true, `xwayland` is added to the core
  # package list, so it cannot be excluded below.
  #
  #   services.desktopManager.cosmic.xwayland.enable = true;   # default

  # --- Core-package exclusion warning --------------------------------------
  # When you exclude a *core* package (see the warning text printed at
  # build time), the module warns because COSMIC can fail to start.
  # Set to false only if you intentionally exclude a core package and
  # accept the breakage.
  #
  #   services.desktopManager.cosmic.showExcludedPkgsWarning = true;  # default

  # --- Exclude optional COSMIC apps ----------------------------------------
  # Remove non-essential packages from the COSMIC environment. Do NOT put
  # core packages here (cosmic-comp, cosmic-session, cosmic-greeter, etc.)
  # or the desktop will refuse to initialize. Known non-core packages:
  # cosmic-edit, cosmic-files, cosmic-monitor, cosmic-player, cosmic-reader,
  # cosmic-screenshot, cosmic-term, cosmic-store, cosmic-wallpapers, ...
  # (cosmic-store is only installed when services.flatpak.enable = true)
  #
  #   environment.cosmic.excludePackages = with pkgs; [
  #     cosmic-edit
  #     cosmic-reader
  #     cosmic-term
  #   ];

  # --- Greeter package override --------------------------------------------
  # Swap the greeter package (e.g. to test a specific git build).
  #
  #   services.displayManager.cosmic-greeter.package = pkgs.cosmic-greeter;  # default

  # --- Autologin (display-manager wide, works with the greeter) ------------
  # Bypass the login screen and drop straight into COSMIC for this user.
  #
  #   services.displayManager.autoLogin = {
  #     enable = true;
  #     user = "harbinger";
  #   };
}
