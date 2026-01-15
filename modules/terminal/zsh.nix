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
      test-build = "sudo nixos-rebuild build --flake .#harbinger";
      rehome = "nix run home-manager/master -- switch --flake .#harbinger";
      find = ''$ nix run "github:thiagokokada/nix-alien#nix-alien-lda" -- '';
      list-system = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
      delete-system = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations";
      garbage = "sudo nix-collect-garbage";

    };

    history.size = 2000;
    history.ignoreAllDups = true;
    history.path = "$HOME/.zsh_history";
    history.ignorePatterns = [ "rm *" "pkill *" "cp *" ];

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "direnv" ];
      theme = "jonathan";
    };
  };
}
