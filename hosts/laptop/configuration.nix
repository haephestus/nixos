# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # configuration for desktop environment
    ../../modules/desktop/hyprland/sys-config.nix
    # configurations for nix-ld and nix-alien
    ../../modules/tools/nix-ld.nix

    # configurations for distrobox
    ../../modules/virtualization/virtualisation.nix

    # nvidia drivers
    ../../modules/desktop/nvidia.nix

    # agentic ai
    ../../modules/ai/coding-agents.nix

    # steward daemon settings
    ../../modules/services/tailscale.nix

    # weekly nix-sweep store cleanup
    ../../modules/services/nix-sweep.nix
  ];
  # Dedupe identical store files via hardlinks after every build (nix.conf
  # auto-optimise-store is currently false; this prevents slow store bloat).
  # Enable flakes
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
  documentation.dev.enable = false;

  # --- Consolidated Boot Block ---
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = [
      "uinput"
      # Explicit NVIDIA modules: nixpkgs only adds these when
      # services.xserver.enable is set, but GNOME/COSMIC run on Wayland
      # without an X server. nvidia_drm is required for the GBM backend
      # (modeset/fbdev) to create /dev/dri nodes.
      "nvidia"
      "nvidia_modeset"
      "nvidia_drm"
    ];
  };

  # --- Stylus / drawing tablet support -----------------------------------
  # OpenTabletDriver handles most physical Wacom/XP-Pen/Huion tablets.
  # uinput is also required by Weylus to inject pressure/tilt events when
  # using an Android tablet as a wireless drawing screen.
  hardware.opentabletdriver.enable = true;
  hardware.uinput.enable = true;

  # --- Consolidated Users Block ---
  users = {
    groups.uinput = { };
    defaultUserShell = pkgs.zsh;
    users.harbinger = {
      isNormalUser = true;
      description = "harbinger";
      extraGroups = [
        "networkmanager"
        "wheel"
        "uinput"
        "input"
        "docker"
      ];
    };
  };
  # Set your time zone.
  time.timeZone = "Africa/Johannesburg";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_ZA.UTF-8";

  # Enable sound with pipewire.
  security.rtkit.enable = true;

  # Cap the systemd journal so logs can't fill the disk (was growing to ~2 GiB).
  services = {
    journald.extraConfig = ''
      SystemMaxUse=200M
      MaxRetentionSec=30d
    '';
    udev.extraRules = ''
      KERNEL=="uinput", GROUP="uinput", MODE="0660"
    '';

    printing.enable = true;
    pulseaudio.enable = false;

    # thumbnailers for Thunar's file previews
    tumbler.enable = true;

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    # drive/phone mounting in Thunar (Devices sidebar) — the udisks2-backed
    # virtual filesystem layer COSMIC used to provide implicitly.
    gvfs.enable = true;
    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      environmentVariables = {
        # --- memory (from before) ---
        OLLAMA_KEEP_ALIVE = "2m";
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_NUM_PARALLEL = "1";
        # --- GPU sharing on a 3GB card ---
        OLLAMA_GPU_OVERHEAD = "1073741824";
        # reserve ~1GB VRAM for Brave/compositor
        # so Ollama shares politely & doesn't OOM the GPU
        OLLAMA_FLASH_ATTENTION = "1"; # enables KV-cache quant below
        OLLAMA_KV_CACHE_TYPE = "q8_0"; # ~half the KV-cache RAM/VRAM, near-lossless
        LLAMA_ARG_FIT = "off";
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  systemd.services.ollama.serviceConfig = {
    MemoryHigh = "9G"; # soft: kernel throttles/reclaims Ollama before it swaps
    MemoryMax = "11G"; # hard ceiling; OOM-kills Ollama, not your whole session
  };

  # Allowed nix users (Fixed leading space typo on root)
  nix.settings.trusted-users = [
    "root"
    "harbinger"
  ];
  # System side — stop the freeze even if something spikes (NixOS config):
  zramSwap.enable = true; # compressed RAM swap; the kernel swaps to RAM instead of the HDD. Single biggest quality-of-life win. Keep the HDD swap as low-prio overflow.
  boot.kernel.sysctl."vm.swappiness" = 10; # stop pre-emptively paging to the HDD.
  # Optionally run conversions under a memory cap that can't touch HDD swap, so a runaway gets killed instead of thrashing:
  # systemd-run --user --scope -p MemoryMax=6G -p MemorySwapMax=0 <cmd>

  #***********************************************************************
  #                                                                      #
  #                    PROGRAM DECLARATION SECTION                       #
  #                                                                      #
  #***********************************************************************

  # I use zsh btw
  environment.shells = with pkgs; [ zsh ];

  programs = {
    zsh.enable = true;
    direnv.nix-direnv.enable = true;
    direnv.enable = true;
    # --- Consolidated Weylus Module Configuration ---
    weylus = {
      enable = true;
      openFirewall = true;
      users = [ "harbinger" ]; # Fixed user string
    };
  };

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  # fonts
  fonts.packages = with pkgs; [
    nerd-fonts.departure-mono
    nerd-fonts.fira-code
    nerd-fonts.daddy-time-mono
  ];

  nixpkgs.config.android_sdk.accept_license = true;

  # List packages installed in system profile.
  # Ownership rule: binaries that are pure apps (ghostty, neovide, zellij)
  # live HERE; Home Manager only customizes their configs via xdg.configFile.
  # Exception: neovim — HM's lazyvim wrapper is inseparable from its config,
  # so it stays HM-owned. Do not re-add plain neovim here (duplicate).
  environment.systemPackages =
    with pkgs;
    let
      prismlauncher = pkgs.symlinkJoin {
        name = "prismlauncher-wrapped";
        paths = [ pkgs.prismlauncher ];
        nativeBuildInputs = [ pkgs.makeWrapper ]; # Use nativeBuildInputs for build tools like makeWrapper
        postBuild = ''
          wrapProgram $out/bin/prismlauncher \
            --set __NV_PRIME_RENDER_OFFLOAD 1 \
            --set __GLX_VENDOR_LIBRARY_NAME nvidia \
            --set DRI_PRIME 1
        '';
      }; # Removed the extra closing parenthesis here
    in
    [
      # dev
      zellij
      sqlite
      ghostty
      python313
      android-tools

      # system manager
      gh
      git
      neovide
      nix-sweep
      home-manager

      # misc
      wget
      xclip
      brave
      ntfs3g
      prismlauncher

      # file management (formerly implicit via COSMIC's cosmic-files)
      thunar # file manager
      file-roller
      unzip
      zip
      p7zip
      swayimg # wayland-native image viewer

      # desktop utilities (formerly implicit via COSMIC)
      pavucontrol # audio device/output mixer — right-click waybar volume module
      btop # system monitor: cpu/mem/disk/processes — Super+U
      brightnessctl # screen backlight control — XF86MonBrightness keys
      playerctl # playback control for MPRIS apps — XF86AudioPlay keys
      pulseaudio
      # CLIENT binaries only (pactl etc.) — PipeWire stays the server;
      # needed by scripts/tools that query audio state via pactl
    ];

  networking = {
    hostName = "nixos";
    networkmanager = {
      enable = true;
      ensureProfiles.profiles = {
        "weylus-hotspot" = {
          connection = {
            id = "weylus-hotspot";
            type = "wifi";
            interface-name = "wlo1"; # Fixed typo: changed wl01 to wlo1
          };
          wifi = {
            mode = "ap";
            ssid = "Weylus";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "somepassword123";
          };
          ipv4 = {
            method = "shared";
          };
          ipv6 = {
            method = "disabled";
          };
        };
      };
    };
  };

  system.stateVersion = "24.11";
}
