# modules/services/backups.nix
#
# Phase 0 — make Steward's data durable BEFORE it holds anything precious.
# Two layers (see steward/docs/03):
#   * litestream : continuous, near-real-time SQLite replication to object
#                  storage (Cloudflare R2 / Backblaze B2). Restore = last few
#                  seconds. This is the high-leverage one.
#   * restic     : nightly versioned, deduplicated, ENCRYPTED snapshots of the
#                  whole data dir (SQLite + vector store) — protects against
#                  corruption/"oops", not just disk death.
#
# ⚠️ SECRETS: bucket keys and the restic password must NOT be inlined (the Nix
# store is world-readable). This module reads them from files/env. Until you
# fill those in, it is written to stay effectively inert — nothing leaves your
# machine. Wire real creds via sops-nix/agenix (ask me to stage that) or a
# root-only EnvironmentFile.
{
  config,
  pkgs,
  ...
}:
let
  dataDir = "/var/lib/steward"; # keep in sync with the steward systemd unit later
in
{
  environment.systemPackages = [
    pkgs.litestream
    pkgs.restic
  ];

  # ── Litestream: continuous SQLite → object storage ────────────────────────
  services.litestream = {
    enable = false; # ← flip to true once dbs[].replicas creds are set below
    # Credentials come from the environment (S3-compatible: R2 or B2).
    # Provide them via a root-only file, e.g. sops/agenix → /run/secrets/litestream:
    #   LITESTREAM_ACCESS_KEY_ID=...
    #   LITESTREAM_SECRET_ACCESS_KEY=...
    environmentFile = "/run/secrets/litestream"; # TODO: create this (sops/agenix)
    settings = {
      dbs = [
        {
          path = "${dataDir}/steward.db";
          replicas = [
            {
              type = "s3";
              bucket = "steward-backups"; # TODO: your bucket
              path = "steward-db";
              # R2 example endpoint; B2 has its own S3 endpoint:
              endpoint = "https://<accountid>.r2.cloudflarestorage.com"; # TODO
              # region = "auto";
            }
          ];
        }
      ];
    };
  };

  # ── Restic: nightly encrypted snapshots of the whole data dir ─────────────
  services.restic.backups.steward = {
    # repository = "s3:https://<accountid>.r2.cloudflarestorage.com/steward-snapshots"; # TODO
    repository = ""; # ← empty = disabled until you set it
    paths = [ dataDir ];
    initialize = true;
    # Restic password + S3 creds via a root-only env file (sops/agenix):
    #   RESTIC_PASSWORD=...
    #   AWS_ACCESS_KEY_ID=...        (R2/B2 key)
    #   AWS_SECRET_ACCESS_KEY=...
    environmentFile = "/run/secrets/restic-steward"; # TODO: create this
    timerConfig = {
      OnCalendar = "02:30";
      Persistent = true; # run on next boot if the machine was off at 02:30
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
    ];
  };
}
