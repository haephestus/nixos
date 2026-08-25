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

      # rebuild system and home manager
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#harbinger";
      upgrade = "sudo nixos-rebuild switch --flake /etc/nixos#harbinger --upgrade";
      test-build = "sudo nixos-rebuild build --flake /etc/nixos#harbinger";
      rehome = "nix run home-manager/master -- switch -b backup --flake /etc/nixos#harbinger";
      rollback = "sudo nixos-rebuild switch --rollback --flake /etc/nixos#harbinger";
      list-system = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
      delete-system = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations";
      garbage = "sudo nix-collect-garbage";

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
  xdg.dataFile."zsh/site-functions/_zellij".source =
    pkgs.runCommand "_zellij" { nativeBuildInputs = [ pkgs.zellij ]; }
      "${pkgs.zellij}/bin/zellij setup --generate-completion zsh > $out";
}
