{
  programs.zsh = {
    enable = true;
    initContent = ''
      source /etc/nixos/scripts/devenv/devshells.sh
      source /etc/nixos/scripts/os/clean.sh

      export PATH=$HOME/Development/flutter/bin:$PATH

      # --- zellij zsh integration ---
      # (replaces programs.zellij.enableZshIntegration, unavailable since
      # zellij went config-only — see modules/terminal/zellij.nix)
      eval "$(zellij setup --gen-completions zsh)"

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
      rehome = "nix run home-manager/master -- switch --flake /etc/nixos#harbinger";
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
}
