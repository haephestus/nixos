# modules/services/nix-sweep.nix
#
# Keep the Nix store from filling the disk: a weekly, fully-automatic
# cleanup of old generations + garbage collection, mirroring the manual
# nix-sweep workflow documented in /etc/nixos/README.md.
#
# Policy: keep the newest generation per profile, drop everything older
# than 30 days, then GC. Logs to the journal: `journalctl -u nix-sweep.service`.
#
# NOTE: profile names like "user"/"home" resolve against the invoking user —
# under root (systemd/`sudo`) they fail with "Could not find profile", and
# /nix/var/nix/profiles/default is a dangling symlink here. Real profiles are
# passed as explicit paths instead.
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
    # nix-sweep errors out ("Unable to read $USER") in a bare systemd
    # service environment; provide the vars it needs.
    environment = {
      USER = "root";
      HOME = "/root";
    };
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${nixSweep} cleanout \
        /nix/var/nix/profiles/system \
        /home/harbinger/.local/state/nix/profiles/profile \
        /home/harbinger/.local/state/nix/profiles/home-manager \
        --keep-min 1 --remove-older 30d --gc
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
