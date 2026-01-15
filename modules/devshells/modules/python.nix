{
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (pkgs)
    stdenv
    lib
    openssl
    zlib
    ;

  baseBuildInputs = with pkgs; [
    python312
    python312Packages.pip
    gcc
    gnumake
  ];

  baseLDenv = {
    NIX_LD = lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";
    NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
      stdenv.cc.cc.lib
      openssl
      zlib
    ];
  };

  # common shellHook for all environments
  commonShellHook = ''
    echo "Python312 dev shell"

    # export runtime linker explicitly
    export NIX_LD=$(nix eval --raw nixpkgs#stdenv.cc.cc.lib)/lib/ld-linux-x86-64.so.2
    export LD_LIBRARY_PATH=$(nix eval --raw nixpkgs#stdenv.cc.cc.lib)/lib:$LD_LIBRARY_PATH
  '';
in
{
  python = pkgs.mkShell {
    buildInputs = baseBuildInputs;
    shellHook = commonShellHook;
    inherit (baseLDenv) NIX_LD NIX_LD_LIBRARY_PATH;
  };

  flask = pkgs.mkShell {
    buildInputs =
      baseBuildInputs
      ++ (with pkgs; [
        python312Packages.flask
        python312Packages.fastapi
      ]);
    shellHook = commonShellHook;
    inherit (baseLDenv) NIX_LD NIX_LD_LIBRARY_PATH;
  };

  insight = pkgs.mkShell {
    buildInputs =
      baseBuildInputs
      ++ (with pkgs.python312Packages; [
        scikit-learn
        statsmodels
        matplotlib
        virtualenv
        jupyterlab
        ipykernel
        notebook
        jupytext
        pandas
        numpy
        pip
      ]);
    shellHook = commonShellHook;
    inherit (baseLDenv) NIX_LD NIX_LD_LIBRARY_PATH;
  };
}
