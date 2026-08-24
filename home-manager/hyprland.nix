# ---------------------------------------------------------------------------
# Hyprland (user session, managed by Home Manager)
#
# ⚠️ MIGRATION DEADLINE: Hyprland 0.55 introduced Lua configs
# (hyprland.lua, see hypr.land/news/26_lua) and hyprlang (.conf) support is
# dropped in ~0.57. This file currently produces hyprland.conf via HM's
# `settings`. Before nixpkgs bumps Hyprland past 0.56.x this must move to a
# hyprland.lua (check whether HM gains lua support; otherwise xdg.configFile
# a hand-written .lua). Watch the nixpkgs Hyprland version.
#
# Window manager config for the standalone home-manager entry point.
# The system-level module (modules/desktop/hyprland.nix) installs the
# compositor; this file configures it per-user.
#
# GPU layout (PRIME offload — see modules/desktop/nvidia.nix): the Intel
# UHD 630 renders; the GTX 1050 is compute + hosts the only HDMI port.
#
# AQ_DRM_DEVICES tells Hyprland/aquamarine to render on the Intel card and
# attach the NVIDIA output in copy mode when a monitor is plugged into it.
# Paths are the colon-free /dev/dri-gpu-* symlinks (system tmpfiles rule in
# modules/desktop/hyprland.nix) — by-path contains colons, which
# aquamarine treats as list separators. Order matters: first = renderer.
# ---------------------------------------------------------------------------

{
  config,
  pkgs,
  ...
}:

{
  wayland.windowManager.hyprland = {
    enable = true;
    # Let HM's module handle systemd session integration
    systemd.enable = true;

    settings = {
      # --- Multi-GPU (PRIME offload) ---
      # ⚠️ Do NOT put /dev/dri/by-path/* here: aquamarine splits this list
      # on ':' and PCI paths contain colons. Use the colon-free symlinks
      # created by modules/desktop/hyprland.nix (systemd tmpfiles).
      env = [
        "AQ_DRM_DEVICES,/dev/dri-gpu-intel:/dev/dri-gpu-nvidia"
      ];

      # Per-display scale + arrangement knobs.
      # Scale = last field of each line (raise to 1.25 if text reads small).
      # Arrangement: the auto-* keyword places each screen relative to the
      # ones declared before it — swap auto-right/auto-left to flip sides,
      # or use explicit pixel coords ("1920x0") for precise alignment.
      # Laptop is eDP-1, external is HDMI-A-2.
      monitor = [
        "eDP-1,preferred,auto,1"
        "HDMI-A-2,preferred,auto,1,auto-right"
      ];

      # Per-workspace layouts (Hyprland 0.54+): workspace 3 uses the
      # core scrolling layout (niri-style column tape); everything else
      # stays on dwindle.
      workspace = [
        "3, layout:scrolling"
      ];

      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$browser" = "brave";
      "$menu" = "fuzzel";

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, B, exec, $browser"
        "$mod, Space, exec, $menu"
        "$mod, Q, killactive"
        # exit moved OFF Super+M: M is fullscreen (COSMIC muscle memory) and
        # an accidental session-logout bind on a home-row key is a footgun.
        "$mod SHIFT, E, exec, hyprctl dispatch exit"
        "$mod, V, togglefloating"
        "$mod, P, pseudo" # dwindle
        "$mod, F, fullscreen"
        "$mod, M, fullscreen" # COSMIC habit

        # focus — arrows AND vim keys
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"

        # cross physical monitors (movefocus cannot leave the screen)
        "$mod SHIFT, H, focusmonitor, l"
        "$mod SHIFT, L, focusmonitor, r"

        # split control — togglesplit/swapsplit dispatchers were REMOVED in
        # Hyprland 0.54; layoutmsg is the only way now. Requires
        # general preserve_split below, or toggling does nothing.
        # (was Super+J — J/K now do workspace up/down, COSMIC habit)
        "$mod, T, layoutmsg, togglesplit"

        # keyboard window resize (repeatable)
        "$mod SHIFT, left, resizeactive, -30 0"
        "$mod SHIFT, right, resizeactive, 30 0"
        "$mod SHIFT, up, resizeactive, 0 -30"
        "$mod SHIFT, down, resizeactive, 0 30"

        # --- scrolling-layout controls (workspace 3) ---
        # layoutmsg is layout-scoped: these only do something on the
        # scrolling workspace; on dwindle workspaces they no-op with a log
        # line. Syntax per wiki 0.54+ Scrolling Layout page.
        "$mod, period, layoutmsg, move +col"      # scroll tape right
        "$mod, comma, layoutmsg, move -col"       # scroll tape left
        "$mod CTRL, period, layoutmsg, colresize +conf" # cycle wider preset
        "$mod CTRL, comma, layoutmsg, colresize -conf"  # cycle narrower preset
        "$mod, O, layoutmsg, promote"             # pop window into own column

        # workspaces: numbers, plus J/K vim-style (j=down/next, k=up/prev)
        "$mod, J, workspace, e+1"
        "$mod, K, workspace, e-1"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"

        # move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"

        # mouse wheel through workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # keybind cheat sheet (Omarchy-style overlay)
        "$mod, slash, exec, hypr-keybinds"

        # wallpaper picker
        "$mod SHIFT, W, exec, waypaper"

        # system monitor (cpu/mem/disk/processes)
        "$mod, U, exec, $terminal -e btop"
      ];

      # tap Super (press and release, no other key) opens the launcher —
      # COSMIC muscle memory. bindr fires on key RELEASE.
      bindr = [
        "$mod, Super_L, exec, $menu"
      ];

      # wallpaper daemon — starts at session launch; waypaper updates its
      # conf (~/.config/hypr/hyprpaper.conf) whenever you pick a wallpaper.
      exec-once = [ "hyprpaper" ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };

      dwindle = {
        # layoutmsg togglesplit is a no-op without preserve_split.
        preserve_split = true;
      };

      # The keybind cheat sheet opens as a pinned floating overlay.
      # Matches the --class/--title passed by the hypr-keybinds script.
      # NOTE: Hyprland 0.53+ windowrule syntax — matchers take `match:`
      # and boolean rules need explicit on/off values.
      windowrule = [
        "match:class ^(hypr-keybinds)$, float on, pin on, size 980 720"
      ];
    };
  };

  # App launcher ($menu). Config owned here so font/scaling travel with it.
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        # dpi-aware=no: fuzzel sizes text by each output's scale factor
        # instead of fixed pixels — this is what keeps it readable on a
        # second monitor with a different scale than the laptop panel.
        dpi-aware = "no";
        font = "DaddyTimeMono Nerd Font:size=12";
        icon-theme = "Adwaita";
        terminal = "ghostty -e";
      };
    };
  };

  # DaddyTime computer-wide for GTK apps (thunar, dialogs, etc.)
  gtk = {
    enable = true;
    font = {
      name = "DaddyTimeMono Nerd Font";
      package = pkgs.nerd-fonts.daddy-time-mono;
      size = 11;
    };
  };

  home.packages = with pkgs; [
    wl-clipboard # wayland clipboard utilities (replaces xclip workflows)
    waypaper # wallpaper picker GUI
    hyprpaper # wallpaper daemon — waypaper writes its conf and drives it

    # Power actions as .desktop entries so they appear IN fuzzel — type
    # "reboot" / "shutdown" into the launcher, COSMIC-style. Works without a
    # password: logind's default polkit policy allows poweroff/reboot/suspend
    # for active local sessions.
    (pkgs.makeDesktopItem {
      name = "poweroff";
      desktopName = "Power Off";
      exec = "systemctl poweroff";
      icon = "system-shutdown";
      categories = [ "System" ];
    })
    (pkgs.makeDesktopItem {
      name = "reboot";
      desktopName = "Reboot";
      exec = "systemctl reboot";
      icon = "system-reboot";
      categories = [ "System" ];
    })
    (pkgs.makeDesktopItem {
      name = "suspend";
      desktopName = "Suspend";
      exec = "systemctl suspend";
      icon = "media-playback-pause";
      categories = [ "System" ];
    })

    (pkgs.writeShellScriptBin "hypr-keybinds" ''
      # Omarchy-style keybind viewer: renders every bind from the ACTIVE
      # hyprland.conf into a floating ghostty overlay. Parsed live from the
      # conf, so it never drifts from what's actually bound.
      #
      # NOTE: reads hyprlang .conf — when the Lua migration happens
      # (see header comment) this parser must move to hyprland.lua.
      set -eu

      CONF="''${HOME}/.config/hypr/hyprland.conf"
      SHEET="$(mktemp)"
      trap 'rm -f "$SHEET"' EXIT

      grep -E '^bind[a-z]*[[:space:]]*=' "$CONF" \
        | sed -E \
            -e 's/[[:space:]]+#.*$//' \
            -e 's/^[a-z]+[[:space:]]*=[[:space:]]*//' \
            -e 's/\$mod/SUPER/g' \
        | awk -F', *' '
            {
              key = $1 "  +  " $2
              action = $3
              for (i = 4; i <= NF; i++) action = action ", " $i
              printf "%-26s %s\n", key, action
            }' \
        | sort > "$SHEET"

      exec ${pkgs.ghostty}/bin/ghostty \
        --class=hypr-keybinds \
        --title=hypr-keybinds \
        -e sh -c "printf '\n KEYBINDS  (q closes)\n\n'; ${pkgs.util-linux}/bin/column -t '$SHEET' | ${pkgs.less}/bin/less"
    '')
  ];

  # Route "open folder" / "open image" to thunar / swayimg by default.
  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "thunar.desktop" ];
    "image/png" = [ "swayimg.desktop" ];
    "image/jpeg" = [ "swayimg.desktop" ];
    "image/gif" = [ "swayimg.desktop" ];
    "image/webp" = [ "swayimg.desktop" ];
  };

  # Status bar (formerly implicit via COSMIC's cosmic-panel).
  # Owned entirely by HM: package + systemd user unit + config stay together,
  # so the bar can never boot without its config or vice versa.
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;

      modules-left = [
        "hyprland/workspaces"
      ];
      modules-center = [
        "clock"
      ];
      modules-right = [
        "tray"
        "cpu"
        "memory"
        "disk"
        "network"
        "battery"
        "pulseaudio"
      ];

      "hyprland/workspaces" = {
        format = "{id}";
        # mark the scrolling workspace so it's identifiable at a glance
        "format-icons" = { };
      };

      cpu = {
        format = "cpu {usage}%";
        interval = 3;
      };

      memory = {
        format = "mem {percentage}%";
        interval = 5;
      };

      disk = {
        format = "disk {percentage_used}%";
        path = "/";
        interval = 30;
        tooltip-format = "{used} used of {total} on {path}";
      };

      clock = {
        format = "{:%a %d %b  %H:%M}";
        tooltip-format = "<big>{:%A %d %B %Y}</big>";
      };

      network = {
        format-wifi = " {essid}";
        format-ethernet = " wired";
        format-disconnected = " offline";
        tooltip-format = "{ifname}: {ipaddr}/{cidr}";
      };

      battery = {
        # plain percentage on purpose: no icon-font glyph roulette
        format = "{capacity}%";
        states.warning = 20;
        states.critical = 10;
      };

      pulseaudio = {
        format = "{volume}%";
        format-muted = "muted";
        # scroll = volume, left-click = mute, right-click = full mixer
        "on-click-right" = "pavucontrol";
      };

      tray = {
        icon-size = 18;
        spacing = 8;
      };
    };

    style = ''
      * {
        font-family: "DaddyTimeMono Nerd Font", sans-serif;
        font-size: 13px;
      }
      window#waybar {
        background: rgba(20, 20, 26, 0.85);
        color: #cdd6f4;
      }
      #workspaces button {
        padding: 0 8px;
        color: #6c7086;
      }
      #workspaces button.active,
      #workspaces button.focused {
        color: #cdd6f4;
      }
    '';
  };

  # Start the polkit agent inside Hyprland sessions.
  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland polkit authentication agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
