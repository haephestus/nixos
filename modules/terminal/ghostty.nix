# Home Manager module — CONFIG ONLY.
#
# The ghostty BINARY is owned by the system profile
# (hosts/laptop/configuration.nix). This module only writes
# ~/.config/ghostty/config. Installing here as well would create a
# duplicate package/desktop entry.
{
  xdg.configFile."ghostty/config".text = ''
    # NOTE: ghostty's config format is bare `key = value` lines — no
    # trailing semicolons, no quotes around values. Quoting makes the
    # parser treat them as part of the value (theme/font silently fail).
    # font-family = undecided
    font-size = 12
    font-family = DaddyTimeMono Nerd Font
    theme = TokyoNight Storm
    # gtk-tabs-location = hidden
  '';
}
