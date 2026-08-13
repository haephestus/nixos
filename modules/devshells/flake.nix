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
      py = import ./modules/python.nix { inherit pkgs; };
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
          inherit (flutter) flutter;

          # java development environments
          inherit (java)
            mc_1_20_1 # explicit 1.20.1 (JDK17)
            mc_latest # newer Minecraft (JDK21 default)
            java17 # plain Java 17 + jdtls (nvim/CLI)
            java21 # plain Java 21 + jdtls (nvim/CLI)
            ;
          # delphi development environments
          del = delphi.delphi;

          # python development environments
          inherit (py)
            pyml # machine learning dev env
            pycerebrum # cerebrum dev env
            insight # data science dev env
            fastapi # fastapi dev env
            pysh # general python shell
            pyfl # flask dev env
            steward # steward dev env
            ;

          # javascript developement environments
          inherit (jsshells) nodejs_22 bun;
        };
      };
    };
}
