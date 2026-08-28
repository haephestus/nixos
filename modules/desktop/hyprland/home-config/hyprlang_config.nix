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
  # Drives: compositor borders/shadows, waybar CSS, fuzzel colors,
  # GTK theme variant, mako notifications.
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

  # Tokyo Night GTK theme (thunar, dialogs, waypaper — all GTK apps).
  # Built from upstream with sassc; variant follows the THEME SWITCH above.
  tokyonight-gtk-theme = pkgs.stdenv.mkDerivation {
    pname = "tokyonight-gtk-theme-${themeName}";
    version = "unstable-2026";
    src = pkgs.fetchFromGitHub {
      owner = "Fausto-Korpsvart";
      repo = "Tokyonight-GTK-Theme";
      rev = "6c340e058e84c1975a038a8e5d1e384477225dc0";
      hash = "sha256-7H2n9wTaW8Db1RejWK071ITV1j5KIuzfql0Tx9WT6zM=";
    };
    nativeBuildInputs = [
      pkgs.sassc
      pkgs.glib
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

  # Niri-style scroll overview, built FROM SOURCE against this exact
  # nixpkgs Hyprland derivation (0.56.2). Upstream flake can't be used:
  # its package has no .override and no inputs to follow, so we drive
  # nixpkgs' own mkHyprlandPlugin directly. Pinned commit f9248ab;
  # bump rev+hash together when updating.
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

in

{
  wayland.windowManager.hyprland = {
    enable = true;
    # Let HM's module handle systemd session integration
    systemd.enable = true;

    # PIN the config format explicitly: newer HM defaults configType to
    # "lua", which would silently change what `settings` generates.
    # Flip to "lua" only as part of the deliberate 0.57 migration
    # (see file header warning).
    configType = "hyprlang";

    plugins = [ scrolloverview ];

    settings = {
      # --- Multi-GPU (PRIME offload) ---
      # ⚠️ Do NOT put /dev/dri/by-path/* here: aquamarine splits this list
      # on ':' and PCI paths contain colons. Use the colon-free symlinks
      # created by modules/desktop/hyprland.nix (systemd tmpfiles).
      env = [
        "AQ_DRM_DEVICES,/dev/dri-gpu-intel:/dev/dri-gpu-nvidia"
      ];

      # Physical arrangement: external HDMI on the LEFT, laptop on the RIGHT.
      # Positions are EXPLICIT pixel coords — the auto-left/auto-right
      # relative keywords are unreliable in 0.56.x (silently disable the
      # output; verified live 2026-08-24). Both panels are 1080p scale 1.
      monitor = [
        "HDMI-A-2,preferred,0x0,1"
        "eDP-1,preferred,1920x0,1"
      ];

      # Per-workspace layouts (Hyprland 0.54+): workspace 3 uses the
      # core scrolling layout (niri-style column tape); everything else
      # stays on dwindle.
      workspace = [
        "1, layout:scrolling"
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

        # focus — full vim semantics: h/j/k/l + arrows
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"

        # cross physical monitors (movefocus cannot leave the screen)
        "$mod SHIFT, H, focusmonitor, l"
        "$mod SHIFT, L, focusmonitor, r"
        "$mod SHIFT, J, focusmonitor, d"
        "$mod SHIFT, K, focusmonitor, u"

        # split control — togglesplit/swapsplit dispatchers were REMOVED in
        # Hyprland 0.54; layoutmsg is the only way now. Requires
        # general preserve_split below, or toggling does nothing.
        "$mod, T, layoutmsg, togglesplit"

        # resize MODE: Super+R enters a dedicated submap (extraConfig at
        # bottom) — arrows/HJKL resize, Esc/Enter exits.
        "$mod, R, submap, resize"

        # --- scrolling-layout controls (workspace 3) ---
        # layoutmsg is layout-scoped: these only do something on the
        # scrolling workspace; on dwindle workspaces they no-op with a log
        # line. Syntax per wiki 0.54+ Scrolling Layout page.
        "$mod, period, layoutmsg, move +col" # scroll tape right
        "$mod, comma, layoutmsg, move -col" # scroll tape left
        "$mod CTRL, period, layoutmsg, colresize +conf" # cycle wider preset
        "$mod CTRL, comma, layoutmsg, colresize -conf" # cycle narrower preset
        "$mod CTRL, H, layoutmsg, swapcol l" # shift column left
        "$mod CTRL, L, layoutmsg, swapcol r" # shift column right
        "$mod, O, layoutmsg, promote" # pop window into own column

        # workspaces: numbers plus Ctrl+J/K (bare J/K are focus now)
        # j = next, k = previous
        "$mod CTRL, J, workspace, e+1"
        "$mod CTRL, K, workspace, e-1"
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
        "$mod ALT, K, workspace, e+1"
        "$mod ALT, J, workspace, e-1"

        # keybind viewer — quickshell widget reading live binds
        "$mod, slash, exec, quickshell ipc call keybinds toggle"

        "$mod SHIFT, W, exec, waypaper"

        # system monitor (cpu/mem/disk/processes)
        "$mod, U, exec, $terminal -e btop"

        # screenshots: Print = whole screen, Shift+S = select region
        ", Print, exec, hypr-screenshot"
        "$mod SHIFT, S, exec, hypr-screenshot region"

        # screen recording: toggle (start / stop+save)
        "$mod SHIFT, R, exec, hypr-record"

        # workspace overview — niri-style scroll overview (plugin above)
        "$mod, Tab, scrolloverview:overview, toggle all"

        # dashboard toggle (quickshell IpcHandler target "dashboard")
        # NOTE: no -c flag — shell.qml IS the default config; -c selects a
        # config DIRECTORY and would fail with "could not find"
        "$mod, D, exec, quickshell ipc call dashboard toggle"
      ];

      # NOTE: media/brightness/playback/wireless keys are NOT in the bind
      # list above — HM normalizes unknown bind-like keys to plain `bind`,
      # destroying bindel/bindl (repeat + locked) semantics. They live in
      # extraConfig below instead.

      # tap Super (press and release, no other key) opens the launcher —
      # COSMIC muscle memory. bindr fires on key RELEASE.
      bindr = [
        "$mod, Super_L, exec, $menu"
      ];

      # wallpaper daemon — starts at session launch; waypaper updates its
      # conf (~/.config/hypr/hyprpaper.conf) whenever you pick a wallpaper.
      # pyprland daemon removed — replaced by the scrolloverview plugin.
      # hyprpaper starts here; mako does NOT (services.mako owns it as a
      # managed user unit — starting both would fight over the socket).
      # quickshell = the dashboard (Super+D toggles it via its IPC handler).
      exec-once = [
        "hyprpaper"
        "quickshell"
      ];

      # dashboard toggle (quickshell IpcHandler target "dashboard") is in
      # the main bind list above.
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        layout = "dwindle";
        # Tokyo Night: blue→cyan gradient on focus, dim slate idle.
        # Hyprland color format = alpha-FIRST: rgba(AARRGGBB).
        "col.active_border" = "rgba(ee${tokyoNight.blue}) rgba(ee${tokyoNight.cyan}) 45deg";
        "col.inactive_border" = "rgba(aa414868)";
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;

        # NO focus-dependent dimming — blur and opacity stay constant
        # regardless of which window is focused (user preference).
        inactive_opacity = 1.0;

        # soft drop shadows, tinted with the palette's dark base
        shadow = {
          enabled = true;
          range = 18;
          render_power = 3;
          color = "rgba(aa${tokyoNight.base})";
        };

        # backdrop blur behind translucent surfaces (waybar, notifications)
        blur = {
          enabled = true;
          size = 6;
          passes = 3;
          vibrancy = 0.17;
          brightness = 0.85;
          noise = 0.02;
        };
      };

      dwindle = {
        # layoutmsg togglesplit is a no-op without preserve_split.
        preserve_split = true;
      };

      windowrule = [
        # thunar's rename dialog: float + center on the focused screen
        # instead of spawning at the side / wrong monitor
        "match:class ^(thunar)$, match:title ^Rename, float on, center on"
        # NOTE: no blur rules needed — decoration.blur applies to ALL
        # windows by default in 0.56+; per-window opt-OUT is `no_blur on`.
      ];
    };

    # Resize MODE — a dedicated submap. Entered via Super+R (bind above);
    # inside it, arrows/HJKL resize the active window, Shift = big steps,
    # and Esc/Enter return to the default submap. Submaps are Hyprland's
    # mechanism for keys meaning different things per mode WITHOUT overlap:
    # binds here shadow root binds only while the mode is active.
    #
    # NOTE: every custom submap MUST bind its own exit — root binds are
    # invisible while inside a submap. Foreign submaps (plugins) that
    # forget their exit are escaped with: hyprctl dispatch submap reset
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

      # --- Tokyo Night rice: motion ---
      # Animations live here (appended after settings) because beziers MUST
      # be defined before the animations referencing them, and the generated
      # settings order can't guarantee that.
      bezier = overshot, 0.05, 0.9, 0.1, 1.05
      bezier = smoothOut, 0.36, 0, 0.66, -0.56
      bezier = smoothIn, 0.25, 1, 0.5, 1

      animation = windows, 1, 5, overshot, slide
      animation = windowsOut, 1, 4, smoothOut
      animation = fade, 1, 6, smoothIn
      animation = workspaces, 1, 5, smoothIn, slidefade 15%
      # borderangle REQUIRES an explicit curve (missing 4th field = "no
      # such bezier"). "linear" is a Hyprland built-in.
      animation = borderangle, 1, 30, linear

      # blur the bar (it's translucent; blur makes it glassy)
      layerrule = blur on, match:namespace waybar

      # --- media/brightness/playback/wireless keys ---
      # In extraConfig because HM normalizes settings.bindel/bindl to plain
      # `bind`, destroying repeat/locked semantics.
      bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
      bindel = , XF86AudioLowerVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-
      bindl  = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindl  = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindel = , XF86MonBrightnessUp, exec, brightnessctl set +5%
      bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
      bindl  = , XF86AudioPlay, exec, playerctl play-pause
      bindl  = , XF86AudioPause, exec, playerctl pause
      bindl  = , XF86AudioNext, exec, playerctl next
      bindl  = , XF86AudioPrev, exec, playerctl previous
      bindl  = , XF86WLAN, exec, nmcli radio wifi toggle
      bindl  = , XF86RFKill, exec, sh -c 'if [ "$(nmcli radio wifi)" = enabled ]; then nmcli radio wifi off; else nmcli radio wifi on; fi; if bluetoothctl show | grep -q "Powered: yes"; then bluetoothctl power off; else bluetoothctl power on; fi'
    '';
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
        # NOTE: fuzzel colors are RRGGBBAA — alpha LAST (opposite of
        # Hyprland's format). Don't "fix" one to match the other.
        line-height = 22;
        horizontal-pad = 24;
        vertical-pad = 14;
        inner-pad = 10;
      };
      border = {
        width = 2;
        radius = 10;
      };
      # fuzzel colors are RRGGBBAA — alpha LAST (opposite of Hyprland's
      # format). Don't "fix" one to match the other.
      colors = {
        background = "${tokyoNight.base}f0"; # palette base, translucent
        text = "${tokyoNight.fg}ff";
        match = "${tokyoNight.cyan}ff";
        selection = "${tokyoNight.sel}ff";
        selection-text = "${tokyoNight.fg}ff";
        selection-match = "${tokyoNight.cyan}ff";
        border = "${tokyoNight.blue}ff";
      };
    };
  };

  # GTK apps (thunar, dialogs, waypaper): Tokyo Night theme + font.
  # Theme dir name must match what the tokyonight-gtk-theme derivation
  # above actually produces ("Tokyonight-Dark" + variant suffix).
  gtk = {
    enable = true;
    theme = {
      name = gtkThemeDir;
      package = tokyonight-gtk-theme;
    };
    # newer HM stopped inheriting the GTK3 theme into gtk4/libadwaita —
    # set both so every generation of app toolkit matches.
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
      /* tighten thunar up a little */
      .thunar toolbar { padding: 2px; }
      window { background-color: #${tokyoNight.bg}; }
    '';
  };

  # quickshell dashboard — audio devices/volume/mute panel (Super+D).
  # v0: talks to PipeWire through wpctl/pactl CLI (Process objects) rather
  # than quickshell's Pipewire service API — less elegant, far fewer
  # unknown-API failure modes. Iterate visually later.
  xdg.configFile."quickshell" = {
    source = ./modules/quickshell;
    recursive = true;
  };

  # Waypaper defaults — SEED-ONLY. waypaper REWRITES this file whenever
  # you pick a wallpaper, so HM must not manage it as a link target
  # (declarative management would clobber your runtime choice every
  # switch, or fail like the -b backup error). We create it once if
  # absent; afterwards waypaper owns it.
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

  # Dark-mode signal for Chromium/Electron apps (Brave, etc.) — they ignore
  # gtk-theme and read org.gnome.desktop.interface color-scheme instead.
  # Without this they render white toolbars on a dark desktop.
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = gtkThemeDir;
  };

  services.mako = {
    enable = true;
    settings = {
      background-color = "#${tokyoNight.base}f0";
      text-color = "#${tokyoNight.fg}ff";
      border-color = "#${tokyoNight.blue}ff";
      border-radius = 10;
      border-size = 2;
      default-timeout = 4000;
      font = "DaddyTimeMono Nerd Font 11";
    };
  };

  home.packages = with pkgs; [
    wl-clipboard # wayland clipboard utilities (replaces xclip workflows)
    waypaper # wallpaper picker GUI
    hyprpaper # wallpaper daemon — waypaper writes its conf and drives it
    quickshell # Qt/QML shell toolkit — dashboard (Super+D)
    grim # screenshot capture
    slurp # region selection for screenshots
    gpu-screen-recorder
    # screen recording — NOTE: wf-recorder is unusable
    # in this nixpkgs rev (fails to build vs ffmpeg 8)
    mako # notification daemon (formerly implicit via COSMIC)

    # Screenshot helper: `hypr-screenshot` = full screen,
    # `hypr-screenshot region` = select area. Saves to ~/Pictures/Screenshots
    # AND copies to clipboard.
    (pkgs.writeShellScriptBin "hypr-screenshot" ''
      set -eu

      dir="$HOME/Pictures/Screenshots"
      mkdir -p "$dir"
      file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"

      if [ "''${1:-}" = "region" ]; then
        geom="$(${pkgs.slurp}/bin/slurp)" || exit 0   # Esc = cancel
        ${pkgs.grim}/bin/grim -g "$geom" "$file"
      else
        ${pkgs.grim}/bin/grim "$file"
      fi

      ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
      ${pkgs.libnotify}/bin/notify-send "Screenshot" "Saved & copied: $(basename "$file")"
    '')

    # Recording toggle: first press starts, second stops and finalizes.
    # gpu-screen-recorder: -w screen captures all monitors, -f 60 fps,
    # -o dir auto-names files. Add `-a default_output` for system audio.
    (pkgs.writeShellScriptBin "hypr-record" ''
      dir="$HOME/Videos"
      mkdir -p "$dir"

      if pgrep -x gpu-screen-recorder >/dev/null; then
        pkill -INT -x gpu-screen-recorder   # graceful stop -> finalize
        ${pkgs.libnotify}/bin/notify-send "Recording stopped" "saved to $dir"
      else
        ${pkgs.libnotify}/bin/notify-send "Recording started" "saving to $dir"
        ${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder \
          -w screen -f 60 -o "$dir"
      fi
    '')

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
      /* Tokyo Night (${themeName}) — generated from the THEME SWITCH
         palette at the top of this file. */
      * {
        font-family: "DaddyTimeMono Nerd Font", sans-serif;
        font-size: 13px;
        min-height: 0;
      }
      window#waybar {
        /* GTK3 CSS has no 8-digit hex — translucency uses alpha():
           alpha(#RRGGBB, fraction). rgba(<hex>, x) also invalid. */
        background: alpha(#${tokyoNight.base}, 0.82);
        color: #${tokyoNight.fg};
        border-bottom: 1px solid alpha(#${tokyoNight.blue}, 0.35);
      }
      #workspaces button {
        padding: 0 10px;
        margin: 3px 2px;
        border-radius: 6px;
        color: #${tokyoNight.dim};
        background: transparent;
        transition: all 0.2s ease;
      }
      #workspaces button.active,
      #workspaces button.focused {
        color: #${tokyoNight.base};
        background: #${tokyoNight.blue};
      }
      #workspaces button:hover {
        background: alpha(#${tokyoNight.blue}, 0.25);
        color: #${tokyoNight.fg};
      }
      #cpu, #memory, #disk, #network, #battery, #pulseaudio, #tray,
      #clock {
        padding: 0 8px;
        margin: 3px 2px;
        border-radius: 6px;
        background: alpha(#${tokyoNight.bg}, 0.65);
      }
      #battery.warning {
        color: #${tokyoNight.warn};
      }
      #battery.critical:not(.charging) {
        color: #${tokyoNight.err};
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
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
