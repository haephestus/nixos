# THIS IS A HOME MANAGER MODULE
{
  config,
  pkgs,
  lazyvim,
  ...
}:

let
  # Python interpreter for nvim's remote plugins (molten.nvim).
  # pynvim        = remote plugin RPC bootstrap
  # jupyter-client= kernel protocol (molten talks to jupyter)
  # ipykernel     = provides the kernelspec registry; without it molten finds
  #                 no kernels to init
  # nbformat      = MoltenExportOutput / MoltenImportOutput (ipynb <-> editor)
  # pillow        = :MoltenImagePopup (plots render in an image viewer)
  #
  # Exposed at a stable path so config/options.lua can point
  # g:python3_host_prog at it (the distro-default host lacks jupyter_client).
  pythonHost = pkgs.python313.withPackages (ps: with ps; [
    ps.pynvim
    ps.jupyter-client
    ps.ipykernel
    ps.nbformat
    ps.pillow
  ]);
in
{
  # magick luarock: LuaJIT + FFI binding around libMagickWand, required by
  # image.nvim — which molten.nvim calls to place image outputs (matplotlib
  # plots etc.) inline under cells.
  #
  # Note: `programs.neovim.extraLuaPackages` looks like the right knob but
  # this nixpkgs' wrapNeovimUnstable has no lua package env and silently
  # IGNORES it. The rock is pure lua (libMagickWand path is baked into the
  # store copy via ffi.load), so adding its store path to LUA_PATH via the
  # wrapper args is all that's needed — the nvim wrapper already composes
  # LUA_PATH this way and keeps the default lua path through the trailing
  # `;;`.
  programs.neovim.extraWrapperArgs =
    let
      magick = pkgs.luajitPackages.magick;
    in
    [
      "--suffix"
      "LUA_PATH"
      ";"
      "${magick}/share/lua/5.1/?.lua;${magick}/share/lua/5.1/?/init.lua;;"
    ];

  programs.lazyvim = {
    enable = true;
    configFiles = ./dotfiles;

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
        jinj = {
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
        kotlin = {
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

      # jupyter notebooks: jupytext pairs .ipynb <-> py:percent scripts
      # (commands/autocmds in dotfiles/lua/config/autocmds.lua). Explicit
      # package-set path: jupytext has no top-level pkgs attribute.
      (pkgs.python313Packages.jupytext)

      # formatters
      google-java-format
      prettier
      pyright
      black
      isort
      nixfmt
      stylua
      shfmt
    ];

  };

  # Dotfiles-side reveal: options.lua points g:python3_host_prog here
  # (guarded by fs_stat there) once this file exists.
  xdg.configFile."nvim/python-host".source = "${pythonHost}/bin/python3";
}
