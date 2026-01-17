{
  config,
  pkgs,
  lazyvim,
  ...
}:

let
  vim-dadbod-fixed = pkgs.vimPlugins.vim-dadbod.overrideAttrs (_: {
    src = pkgs.fetchFromGitHub {
      owner = "tpope";
      repo = "vim-dadbod";
      rev = "e95afed23712f969f83b4857a24cf9d59114c2e6";
      sha256 = "sha256-yTPha6/d62DQ0M13JT70X/szkWO87oiw0y4L93FDLq0=";
    };
  });
in
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
      vim-dadbod-fixed
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
