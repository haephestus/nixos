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
  lib,
  ...
}:

let
  # ══════════════════════════════════════════════════════════════════
  #  THEME SWITCH — change this one word, rebuild, everything reskins:
  #    "storm" | "moon" | "night"
  themeName = "storm";

  tokyoNight =
    {
      storm = {
        bg = "24283b";
        base = "1a1b26";
        fg = "c0caf5";
        dim = "565f89";
        blue = "7aa2f7";
        cyan = "7dcfff";
        sel = "343a55";
        warn = "e0af68";
        err = "f7768e";
        gtkTweaks = "storm";
        gtkSuffix = "-Storm";
      };
      moon = {
        bg = "222436";
        base = "1b1d2b";
        fg = "c8d3f5";
        dim = "585e76";
        blue = "8caaee";
        cyan = "7dcfff";
        sel = "2f334d";
        warn = "ffc777";
        err = "ff757f";
        gtkTweaks = "moon";
        gtkSuffix = "-Moon";
      };
      night = {
        bg = "1a1b26";
        base = "16161e";
        fg = "c0caf5";
        dim = "565f89";
        blue = "7aa2f7";
        cyan = "7dcfff";
        sel = "292e42";
        warn = "e0af68";
        err = "f7768e";
        gtkTweaks = "";
        gtkSuffix = "";
      };
    }
    .${themeName};

  tokyonight-gtk-theme = pkgs.stdenv.mkDerivation {
    pname = "tokyonight-gtk-theme-${themeName}";
    version = "unstable-2026";
    src = pkgs.fetchFromGitHub {
      owner = "tokyonight";
      repo = "Tokyonight-GTK-Theme";
      rev = "6c340e058e84c1975a038a8e5d1e384477225dc0";
      hash = "sha256-7H2n9wTaW8Db1RejWK071ITV1j5KIuzfql0Tx9WT6zM=";
    };
    nativeBuildInputs = [
      pkgs.sassc
      pkgs.python3
    ];
    dontBuild = true;
    postPatch = "patchShebangs themes/install.sh";
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/themes
      cd themes
      ./install.sh -d $out/share/themes -n Tokyonight -c dark -t default ${
        if tokyoNight.gtkTweaks != "" then "--tweaks ${tokyoNight.gtkTweaks}" else ""
      }
      runHook postInstall
    '';
  };
  gtkThemeDir = "Tokyonight-Dark${tokyoNight.gtkSuffix}";

  scrolloverview = pkgs.hyprlandPlugins.mkHyprlandPlugin {
    pluginName = "scrolloverview";
    version = "unstable-2026-08-10";
    src = pkgs.fetchFromGitHub {
      owner = "yayuuu";
      repo = "hyprland-scroll-overview";
      rev = "f9248ab6bee770e9d68813b48cc6ca12b3271254";
      hash = "sha256-SEa8XQtrNg90AUeZFE9+lGvYEWd0T2ht/+sKx+kWUak=";
    };
    meta.description = "Niri-style scroll overview plugin for Hyprland";
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp ./scrolloverview.so $out/lib/libscrolloverview.so
      runHook postInstall
    '';
  };

  # Import the extracted waybar module, passing theme variables.
  # waybarModule = import ./waybar.nix {
  #   inherit
  #     config
  #     pkgs
  #     lib
  #     themeName
  #     tokyoNight
  #     ;
  # };

in

{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    configType = "hyprlang";
    plugins = [ scrolloverview ];

    settings = {
      env = [ "AQ_DRM_DEVICES,/dev/dri-gpu-intel:/dev/dri-gpu-nvidia" ];
      monitor = [
        "HDMI-A-2,preferred,0x0,1"
        "eDP-1,preferred,1920x0,1"
      ];
      workspace = [
        "1, layout:scrolling"
        "3, layout:scrolling"
      ];

      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$browser" = "brave";
      "$menu" = "rofi -show drun";

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, B, exec, $browser"
        "$mod, Space, exec, $menu"
        "$mod, Q, killactive"
        "$mod SHIFT, E, exec, hyprctl dispatch exit"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, F, fullscreen"
        "$mod, M, fullscreen"

        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"

        "$mod SHIFT, H, focusmonitor, l"
        "$mod SHIFT, L, focusmonitor, r"
        "$mod SHIFT, J, focusmonitor, d"
        "$mod SHIFT, K, focusmonitor, u"

        "$mod, T, layoutmsg, togglesplit"
        "$mod, R, submap, resize"

        "$mod, period, layoutmsg, move +col"
        "$mod, comma, layoutmsg, move -col"
        "$mod CTRL, period, layoutmsg, colresize +conf"
        "$mod CTRL, comma, layoutmsg, colresize -conf"
        "$mod CTRL, H, layoutmsg, swapcol l"
        "$mod CTRL, L, layoutmsg, swapcol r"
        "$mod, O, layoutmsg, promote"

        "$mod CTRL, J, workspace, e+1"
        "$mod CTRL, K, workspace, e-1"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"

        "$mod ALT, K, workspace, e+1"
        "$mod ALT, J, workspace, e-1"

        "$mod, slash, exec, quickshell ipc call keybinds toggle"
        "$mod SHIFT, W, exec, waypaper"
        "$mod, U, exec, $terminal -e btop"

        ", Print, exec, hypr-screenshot"
        "$mod SHIFT, S, exec, hypr-screenshot region"
        "$mod SHIFT, R, exec, hypr-record"

        "$mod, TAB, scrolloverview:overview, toggle all"
        "$mod, D, exec, quickshell ipc call dashboard toggle"
      ];

      bindr = [ "$mod, Super_L, exec, $menu" ];

      exec-once = [
        "waypaper --restore"
        "quickshell"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        layout = "dwindle";
        "col.active_border" = "rgba(ee${tokyoNight.blue}) rgba(ee${tokyoNight.cyan}) 45deg";
        "col.inactive_border" = "rgba(aa414868)";
      };

      decoration = {
        rounding = 10;
        active_opacity = 0.95;
        inactive_opacity = 0.85;
        shadow = {
          enabled = true;
          range = 18;
          render_power = 3;
          color = "rgba(aa${tokyoNight.base})";
        };
        blur = {
          enabled = true;
          size = 6;
          passes = 3;
          vibrancy = 0.17;
          brightness = 0.85;
          noise = 0.02;
        };
      };

      dwindle.preserve_split = true;

      windowrule = [
        "match:class ^(thunar)$, match:title ^Rename, float on, center on"
      ];
    };

    extraConfig = ''
      submap = resize
      binde = , right, resizeactive, 30 0
      binde = , left, resizeactive, -30 0
      binde = , up, resizeactive, 0 -30
      binde = , down, resizeactive, 0 30
      binde = , l, resizeactive, 30 0
      binde = , h, resizeactive, -30 0
      binde = , k, resizeactive, 0 -30
      binde = , j, resizeactive, 0 30
      binde = SHIFT, right, resizeactive, 100 0
      binde = SHIFT, left, resizeactive, -100 0
      binde = SHIFT, up, resizeactive, 0 -100
      binde = SHIFT, down, resizeactive, 0 100
      bind  = , escape, submap, reset
      bind  = , return, submap, reset
      submap = reset

      bezier = overshot, 0.05, 0.9, 0.1, 1.05
      bezier = smoothOut, 0.36, 0, 0.66, 0.3
      bezier = smoothIn, 0.25, 1, 0.5, 1

      animation = windows, 1, 5, overshot, slide
      animation = windowsOut, 1, 4, smoothOut
      animation = fade, 1, 6, smoothIn
      animation = workspaces, 1, 5, smoothIn, slidefade 15%
      animation = borderangle, 1, 30, linear

      layerrule = blur on, match:namespace waybar
      layerrule = blur on, match:namespace quickshell
      layerrule = ignore_alpha 0.2, match:namespace quickshell

      bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
      bindel = , XF86AudioLowerVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-
      bind  = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bind  = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindel = , XF86MonBrightnessUp, exec, brightnessctl set +5%
      bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
      bind  = , XF86AudioPlay, exec, playerctl play-pause
      bindl  = , XF86AudioPause, exec, playerctl pause
      bind  = , XF86AudioNext, exec, playerctl next
      bind  = , XF86AudioPrev, exec, playerctl previous
      bindl  = , XF86RFKill, exec, nmcli radio wifi toggle
      bind  = , XF86WLAN, exec, sh -c 'if [ "$(nmcli radio wifi)" = enabled ]; then nmcli radio wifi off; else nmcli radio wifi on; fi; if bluetoothctl show | grep -q "Powered: yes"; then bluetoothctl power off; else bluetoothctl power on; fi'
    '';
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;

    font = "JetBrainsMono Nerd Font 12";

    theme =
      let
        inherit (config.lib.formats.rasi) mkLiteral;
      in
      {
        "*" = {
          bg = mkLiteral "#${tokyoNight.base}f2";
          fg = mkLiteral "#${tokyoNight.fg}ff";
          muted = mkLiteral "#${tokyoNight.fg}99";
          accent = mkLiteral "#${tokyoNight.cyan}ff";
          selection = mkLiteral "#${tokyoNight.sel}ff";
          border-color = mkLiteral "#${tokyoNight.blue}ff";
        };

        window = {
          background-color = mkLiteral "@bg";
          border = mkLiteral "2px";
          border-color = mkLiteral "@border-color";
          border-radius = mkLiteral "12px";

          width = mkLiteral "520px";
          padding = mkLiteral "14px";
        };

        mainbox = {
          background-color = mkLiteral "transparent";
          children = mkLiteral "[ inputbar, listview ]";
          spacing = mkLiteral "8px";
        };

        inputbar = {
          children = mkLiteral "[ prompt, entry ]";
          background-color = mkLiteral "transparent";
          padding = mkLiteral "6px 4px";
          spacing = mkLiteral "8px";
        };

        prompt = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@accent";
        };

        entry = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@fg";
          placeholder = "Search…";
          placeholder-color = mkLiteral "@fg";
        };

        listview = {
          background-color = mkLiteral "transparent";
          columns = mkLiteral "1";
          lines = 8;
          spacing = mkLiteral "4px";
          scrollbar = false;
        };

        # Normal entries
        "element normal" = {
          padding = mkLiteral "8px 10px";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@fg";
          border-radius = mkLiteral "7px";
        };

        # Alternating entries
        "element alternate" = {
          padding = mkLiteral "8px 10px";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@fg";
          border-radius = mkLiteral "7px";
        };

        # Selected entry
        "element selected" = {
          background-color = mkLiteral "@selection";
          text-color = mkLiteral "@fg";
          border-radius = mkLiteral "7px";
        };

        "element-text" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
          vertical-align = mkLiteral "0.5";
        };

        "element-icon" = {
          background-color = mkLiteral "transparent";
          size = mkLiteral "24px";
          padding = mkLiteral "0 8px 0 0";
        };
      };
  };

  gtk = {
    enable = true;
    theme = {
      name = gtkThemeDir;
      package = tokyonight-gtk-theme;
    };
    gtk4.theme = {
      name = gtkThemeDir;
      package = tokyonight-gtk-theme;
    };
    font = {
      name = "DaddyTimeMono Nerd Font";
      package = pkgs.nerd-fonts.daddy-time-mono;
      size = 11;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraCss = ''
      .thunar toolbar { padding: 2px; }
      window { background-color: #${tokyoNight.bg}; }
    '';
  };

  xdg.configFile."quickshell" = {
    source = ../quickshell;
    recursive = true;
  };

  home.activation.seedWaypaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -f "$HOME/.config/waypaper/config.ini" ]; then
          mkdir -p "$HOME/.config/waypaper"
          cat > "$HOME/.config/waypaper/config.ini" <<'EOF'
    [Settings]
    language = en
    folder = /home/harbinger/Pictures/tokyonight
    backend = hyprpaper
    monitor = All
    EOF
        fi
  '';

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = gtkThemeDir;
  };

  #mako = {
  #  enable = true;
  #  settings = {
  #    background-color = "#${tokyoNight.base}f0";
  #    text-color = "#${tokyoNight.fg}ff";
  #    border-color = "#${tokyoNight.blue}ff";
  #    border-radius = 10;
  #    border-size = 2;
  #    default-timeout = 4000;
  #    font = "DaddyTimeMono Nerd Font 11";
  #  };
  #};

  home.packages = with pkgs; [
    wl-clipboard
    waypaper
    hyprpaper
    quickshell
    grim
    slurp
    gpu-screen-recorder
    mako

    (pkgs.writeShellScriptBin "hypr-screenshot" ''
      set -eu
      dir="$HOME/Pictures/Screenshots"
      mkdir -p "$dir"
      file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
      if [ "''${1:-}" = "region" ]; then
        geom="$(${pkgs.slurp}/bin/slurp)" || exit 0
        ${pkgs.grim}/bin/grim -g "$geom" "$file"
      else
        ${pkgs.grim}/bin/grim "$file"
      fi
      ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
      ${pkgs.libnotify}/bin/notify-send "Screenshot" "Saved & copied: $(basename "$file")"
    '')

    (pkgs.writeShellScriptBin "hypr-record" ''
      dir="$HOME/Videos"
      mkdir -p "$dir"
      if pgrep -x gpu-screen-recorder >/dev/null; then
        pkill gpu-screen-recorder
        ${pkgs.libnotify}/bin/notify-send "Recording stopped" "saved to $dir"
      else
        ${pkgs.libnotify}/bin/notify-send "Recording started" "saving to $dir"
        ${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder -w screen -f 60 -o "$dir"
      fi
    '')

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
  ];

  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "thunar.desktop" ];
    "image/png" = [ "swayimg.desktop" ];
    "image/jpeg" = [ "swayimg.desktop" ];
    "image/gif" = [ "swayimg.desktop" ];
    "image/webp" = [ "swayimg.desktop" ];
  };

  # Merge in the extracted waybar module.
  # programs.waybar = waybarModule.programs.waybar;

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
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
