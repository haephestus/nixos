{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    # Completion functions must live on fpath BEFORE compinit runs —
    # `eval`-ing generated completion scripts in .zshrc invokes completion
    # helpers outside a completion widget ("can only be called from
    # completion function"). The _zellij file below is generated at build
    # time and picked up by compinit via this fpath prepend.
    completionInit = "fpath=($HOME/.local/share/zsh/site-functions $fpath); autoload -U compinit && compinit";
    initContent = ''
      # Standalone home-manager installs binaries under
      # ~/.local/state/nix/profiles/home-manager/home-path/bin — NixOS's
      # /etc/profile resets PATH without this dir, which made every HM
      # package invisible in interactive shells (pypr/waypaper "not found").
      export PATH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$PATH"

      source /etc/nixos/scripts/devenv/devshells.sh
      source /etc/nixos/scripts/os/clean.sh

      export PATH=$HOME/Development/flutter/bin:$PATH

      # --- zellij zsh integration ---
      # (replaces programs.zellij.enableZshIntegration, unavailable since
      # zellij went config-only — see modules/terminal/zellij.nix)
      # Completions are NOT eval'd here — see completionInit above and the
      # xdg.dataFile rule below.

      # Optional: auto-attach/auto-start zellij in interactive terminals.
      # Skipped inside existing sessions ($ZELLIJ) and when another program
      # owns the terminal. Uncomment to enable.
      # if [[ -z "$ZELLIJ" && "$TERM_PROGRAM" != "ghostty" ]]; then
      #   [[ $(zellij list-sessions | wc -l) -gt 0 ]] && zellij attach || zellij
      # fi
    '';
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {

      vi = "nvim";
      ll = "ls -l";

      # ── Build / switch ────────────────────────────────────────────
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#harbinger";
      test-build = "sudo nixos-rebuild build --flake /etc/nixos#harbinger";
      dry-build = "sudo nixos-rebuild dry-activate --flake /etc/nixos#harbinger";
      rehome = "nix run home-manager/master -- switch -b backup --flake /etc/nixos#harbinger";
      rollback = "sudo nixos-rebuild switch --rollback --flake /etc/nixos#harbinger";

      # --upgrade does nothing with flakes, so update the lock file first
      upgrade = "sudo nix flake update --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#harbinger";

      # ── Inspect disk usage ────────────────────────────────────────
      disk = "df -h / /boot";
      big-dirs = "sudo du -xh --max-depth=1 / 2>/dev/null | sort -h | tail -15";
      home-big = "du -h --max-depth=1 ~ 2>/dev/null | sort -h | tail -15";
      store-size = "du -sh /nix/store";
      store-top = "nix path-info -rSh /run/current-system | sort -hk2 | tail -25";
      gc-roots = "nix-store --gc --print-roots | grep -v -e '/proc/' -e '{memory}' -e '{censored}'";
      journal-size = "journalctl --disk-usage";

      # ── Generations ───────────────────────────────────────────────
      list-system = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
      list-home = "home-manager generations 2>/dev/null || nix-env --list-generations";
      sys-diff = "nix store diff-closures /run/booted-system /run/current-system";
      keep-5 = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5 && sudo /run/current-system/bin/switch-to-configuration boot";
      delete-system = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations"; # usage: delete-system 12 13 14

      # ── Cleanup ───────────────────────────────────────────────────
      # Safe: keep the last 7 days of generations, vacuum logs, refresh boot entries
      clean = "sudo nix-collect-garbage --delete-older-than 7d && nix-collect-garbage --delete-older-than 7d && sudo journalctl --vacuum-time=7d && sudo /run/current-system/bin/switch-to-configuration boot";

      # Aggressive: delete ALL old generations (you lose rollback), keeps only the current one
      clean-all = "sudo nix-collect-garbage -d && nix-collect-garbage -d && sudo journalctl --vacuum-size=200M && sudo /run/current-system/bin/switch-to-configuration boot";

      garbage = "sudo nix-collect-garbage && nix-collect-garbage";
      optimise = "nix store optimise"; # dedupe the store; slow the first time
      docker-clean = "docker system prune -af --volumes";
      cache-clean = "rm -rf ~/.cache/* 2>/dev/null; echo done";

      # ── Cleanup (nix-sweep) ───────────────────────────────────────
      # See what would be removed, no changes made
      sweep-dry = "sudo nix-sweep cleanout --dry-run --keep-min 5 --keep-newer 7 --gc system && nix-sweep cleanout --dry-run --keep-min 5 --keep-newer 7 user home";

      # Normal cleanup: keep at least 5 generations and anything from the last 7 days
      sweep = "sudo nix-sweep cleanout --keep-min 5 --keep-newer 7 --gc system && nix-sweep cleanout --keep-min 5 --keep-newer 7 --gc user home && sudo /run/current-system/bin/switch-to-configuration boot";

      # Aggressive: keep only the 2 newest generations, regardless of age
      sweep-hard = "sudo nix-sweep cleanout --keep-min 2 --keep-newer 1 --gc system && nix-sweep cleanout --keep-min 2 --keep-newer 1 --gc user home && sudo /run/current-system/bin/switch-to-configuration boot";

      # Interactive: pick generations yourself
      sweep-pick = "sudo nix-sweep cleanout --interactive --gc system && nix-sweep cleanout --interactive --gc user home";

      # GC roots (result symlinks, old direnv envs, etc.)
      sweep-roots = "nix-sweep gc-roots";
      sweep-roots-rm = "nix-sweep gc-roots --interactive";

      # Overview of what's taking space
      sweep-info = "nix-sweep generations system user home";

    };

    history = {
      size = 2000;
      ignoreAllDups = true;
      path = "$HOME/.zsh_history";
      ignorePatterns = [
        "rm *"
        "pkill *"
        "cp *"
      ];
    };

    oh-my-zsh = {
      enable = false;
      plugins = [
        "git"
        "direnv"
      ];
      theme = "agnoster";
    };
  };

  # zellij tab-completions, generated at BUILD time into fpath.
  # Regenerated automatically whenever the zellij version changes.
  xdg.dataFile."zsh/site-functions/_zellij".source = pkgs.runCommand "_zellij" {
    nativeBuildInputs = [ pkgs.zellij ];
  } "${pkgs.zellij}/bin/zellij setup --generate-completion zsh > $out";
}
