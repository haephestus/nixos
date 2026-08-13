{
  programs.zsh = {
    enable = true;
    initContent = ''
      source /etc/nixos/scripts/devenv/devshells.sh
      source /etc/nixos/scripts/os/clean.sh

      export PATH=$HOME/Development/flutter/bin:$PATH
    '';
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {

      vi = "nvim";
      ll = "ls -l";

      # rebuild system and home manager
      rebuild = "sudo nixos-rebuild switch --flake .#harbinger";
      upgrade = "sudo nixos-rebuild switch --flake .#harbinger --upgrade";
      test-build = "sudo nixos-rebuild build --flake .#harbinger";
      rehome = "nix run home-manager/master -- switch --flake .#harbinger";
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
