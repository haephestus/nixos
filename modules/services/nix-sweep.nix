# modules/services/nix-sweep.nix
#
# Keep the Nix store from filling the disk: a weekly, fully-automatic
# cleanup of old generations + garbage collection, mirroring the manual
# nix-sweep workflow documented in /etc/nixos/README.md.
#
# Policy: keep the newest generation per profile, drop everything older
# than 30 days, then GC. Logs to the journal: `journalctl -u nix-sweep.service`.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  nixSweep = "${pkgs.nix-sweep}/bin/nix-sweep";
in
{
  systemd.services.nix-sweep = {
    description = "Trim old Nix generations and garbage-collect the store";
    path = [ pkgs.nix-sweep ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${nixSweep} cleanout -n system user home --keep-min 1 --remove-older 30d --gc
    '';
  };

  systemd.timers.nix-sweep = {
    description = "Weekly Nix store cleanup (nix-sweep)";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true; # run on next boot if the machine was off
      RandomizedDelaySec = "1h"; # spread out across the night
    };
  };
}
