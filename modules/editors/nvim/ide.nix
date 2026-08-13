# THIS IS A HOME MANAGER MODULE
#
# Declarative Neovide config — mirrors the full option tree from
# https://home-manager.dev/manual/unstable/options/home-manager/programs/neovide.html
#
# Every option is present below for documentation. Unused options are commented
# out; only `enable`, `package`, and `settings` are active.
#
# The module writes:
#   programs.neovide.settings → ~/.config/neovide/config.toml
#
# The `settings` value is free-form TOML (type: TOML value). The keys available
# in it come from Neovide itself, not home-manager:
#   https://neovide.dev/config-file.html
# ⚠️ Key names containing `-` must be quoted in Nix: "title-hidden" = true;
{
  pkgs,
  ...
}:
{
  programs.neovide = {
    # ── programs.neovide.enable ──────────────────────────────────────────────
    # type: boolean   default: false
    # Whether to enable Neovide. Installs pkgs.neovide and writes config.toml.
    enable = true;

    # ── programs.neovide.package ─────────────────────────────────────────────
    # type: null or package   default: pkgs.neovide
    # Override the neovide package.
    package = pkgs.neovide;

    # ── programs.neovide.settings ────────────────────────────────────────────
    # type: TOML value   default: { }
    # Written to ~/.config/neovide/config.toml. All keys below are the Neovide
    # config-file options — uncomment what you need.
    settings = {
      # ── Window / layout ──────────────────────────────────────────────────────
      # frame = "full";            # "full" | "thin" | "none"
      # maximized = false;         # mutually exclusive with `grid` and `size`
      size = "1920x1080"; # mutually exclusive with `grid`/`maximized`
      # grid = "420x240";          # grid size; mutually exclusive with `size`/`maximized`
      # title-hidden = true;       # hide the window title bar
      # startup-message-capture = true;
      # idle = true;               # true = better performance; false = always redraw

      # ── Font ─────────────────────────────────────────────────────────────────
      font = {
        #   normal = [ "MonoLisa Nerd Font" ];  # list of family strings or {family,style}
        size = 12.0; # required
        #    width = 0;                        # font width override (integer)
        #    hinting = "full";                 # "none" | "slight" | "full"
        #    edging = "antialias";             # "none" | "antialias" | "subpixel-antialias"
        #    underline_offset = -1.0;          # float, baseline→underline offset
        #    bold = [ { family = "JetBrainsMono Nerd Font Propo"; style = "W600"; } ];
        #    italic = [ "MonoLisa Nerd Font" ];
        #    bold_italic = [ "MonoLisa Nerd Font" ];
        #    features = { "MonoLisa Nerd Font" = [ "+ss01" "-calt" "ss02=2" ]; };
      };

      # ── Box drawing (fractions / gaps in box glyphs) ─────────────────────────
      # box-drawing = {
      #   mode = "native";       # "font-glyph" | "native" | "selected-native"
      #   # selected = "🮐🮑🮒"; # only for "selected-native"
      #   sizes = {
      #     default = [ 2 4 ];  # thin & thick widths in px for all font sizes
      #     # "12" = [ 1 2 ];   # override per font size (px) — numeric keys need quotes
      #     # "14" = [ 2 4 ];
      #   };
      # };

      # ── Behaviour ────────────────────────────────────────────────────────────
      # fork = false;            # fork into background on launch
      # tabs = true;             # render nvim tabs as GUI tabs
      # vsync = true;
      # srgb = false;            # macOS: false | Windows: true (platform-specific)
      # no-multigrid = false;
      # neovim-bin = "/usr/bin/nvim";   # path to the nvim binary
      # wsl = false;             # running under WSL (Windows)
      # opengl = false;          # OpenGL renderer (macOS/Windows only)
      # mouse-cursor-icon = "arrow";
      # icon = "/full/path/to/neovide.ico";  # custom window icon (.ico/.icns)
      # server = "/tmp/nvim.sock";           # or "127.0.0.1:7777"
      # chdir = "/path/to/dir";
      # backtraces-path = "/path/to/neovide_backtraces.log";  # crash log location

      # ── Linux / Wayland / X11 ────────────────────────────────────────────────
      # wayland-app-id = "neovide";
      # x11-wm-class = "neovide";
      # x11-wm-class-instance = "neovide";

      # ── macOS only ───────────────────────────────────────────────────────────
      # system-native-tabs = false;
      # system-pinned-hotkey = "cmd+ctrl+z";
      # system-switcher-hotkey = "cmd+ctrl+n";
      # system-new-window-hotkey = "cmd+n";
      # system-hide-hotkey = "cmd+h";
      # system-hide-others-hotkey = "cmd+alt+h";
      # system-quit-hotkey = "cmd+q";
      # system-minimize-hotkey = "cmd+m";
      # system-fullscreen-hotkey = "cmd+ctrl+f";
      # system-show-all-tabs-hotkey = "cmd+shift+e";
      # system-tab-prev-hotkey = "cmd+shift+[";
      # system-tab-next-hotkey = "cmd+shift+]";
    };
  };
}
