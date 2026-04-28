{
  # define what the flake.nix does
  description = "An experimental devshell for my dev-environments";

  # define the inputs that i will use to define the where to draw the pkgs
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  # what i want the pkgs to do
  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };

      cshells = import ./modules/cshells.nix { inherit pkgs; };
      flutter = import ./modules/flutter.nix { inherit pkgs; };
      java = import ./modules/java.nix { inherit pkgs; };
      play = import ./modules/play.nix { inherit pkgs; };
      pyshells = import ./modules/pyshell.nix { inherit pkgs; };
      python = import ./modules/python.nix { inherit pkgs; };
      jsshells = import ./modules/jsshells.nix { inherit pkgs; };
      delphi = import ./modules/delphi.nix { inherit pkgs; };

    in
    {
      devShells = {
        ${system} = {
          # TODO: add a default shell so that direnv stops complaining
          # TODO: shell hooks are not working
          # TODO: define machine learning shell

          # c/cpp development environments
          gcc = cshells.gcc-shell;
          clang = cshells.clang-shell;

          # flutter development environments
          flutter = flutter.flutter;

          # java development environments
          mc = java.mc_dev;

          # delphi development environments
          del = delphi.delphi;

          # python development environments
          pyml = pyshells.pyml;
          cerebrum = pyshells.pycerebrum;
          insight = python.insight;
          fastapi = python.fastapi;
          pysh = pyshells.pyshell;
          pyfl = pyshells.pyflask;

          # javascript developement environments
          bun = jsshells.bun;
          nodejs_22 = jsshells.nodejs_22;
        };
      };
    };
}
