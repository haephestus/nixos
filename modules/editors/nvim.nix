{
  config,
  pkgs,
  lazyvim,
  ...
}:

{
  programs.lazyvim = {
    enable = true;
    configFiles = ../../dotfiles/nvim;

    extras = {
      lang = {
        nix = {
          enable = true;
          installDependencies = true;
        };
        python = {
          enable = true;
          installDependencies = true;
          installRuntimeDependencies = true;
        };
        html = {
          enable = true;
          installDependencies = true;
          installRuntimeDependencies = true;
        };
        typescript = {
          enable = true;
          installDependencies = true;
          installRuntimeDependencies = true;
        };
        java = {
          enable = true;
          installDependencies = true;
        };
        dart = {
          enable = true;
          installDependencies = true;
        };
      };
    };

    extraPackages = with pkgs; [
      # core utilities
      tree-sitter
      alejandra
      statix
      nixd
      gcc

      # formatters
      google-java-format
      pyright
      black
      isort
      nixfmt
      stylua
      shfmt
    ];

  };
}
