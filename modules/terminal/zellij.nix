# Home Manager module — CONFIG ONLY.
#
# The zellij BINARY is owned by the system profile
# (hosts/laptop/configuration.nix). This module only writes
# ~/.config/zellij/config.kdl. Installing here as well would create a
# duplicate package.
{
  # programs.zellij.enableZshIntegration = true;   # HM-module-only option,
  #                                                # unavailable in config-only mode
  xdg.configFile."zellij/config.kdl".text = ''
    simplified_ui true
    theme "tokyo-night-dark"
    show_status_bar false
    pane_frames false
  '';
}
