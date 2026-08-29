# waybar.nix — extracted from the main Home Manager config.
# Takes theme variables so the bar reskins with the THEME SWITCH.
{
  config,
  pkgs,
  lib,
  themeName, # "storm" | "moon" | "night"
  tokyoNight, # the palette attrset for the chosen theme
}:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;

      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
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
        format = "{capacity}%";
        states.warning = 20;
        states.critical = 10;
      };

      pulseaudio = {
        format = "{volume}%";
        format-muted = "muted";
        "on-click-right" = "pavucontrol";
      };

      tray = {
        icon-size = 18;
        spacing = 8;
      };
    };

    style = ''
      /* Tokyo Night (${themeName}) */
      * {
        font-family: "DaddyTimeMono Nerd Font", sans-serif;
        font-size: 13px;
        min-height: 0;
      }
      window#waybar {
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
}
