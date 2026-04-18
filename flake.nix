{
  inputs = {
    # Nixppkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home-manager
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # lazyvim
    lazyvim.url = "github:pfassina/lazyvim-nix/v15.13.0"; # Pin to v15.13.0

    # NVF
    nvf.url = "github:notashelf/nvf";

    # ngrok
    ngrok.url = "github:ngrok/ngrok-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nvf,
      lazyvim,
      ngrok,
      ...
    }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      customNeovim = nvf.lib.neovimConfiguration { inherit pkgs; };
    in
    {
      # nixos configuration entry point
      # 'nixos-rebuild switch --flake .#hosthame'
      nixosConfigurations = {
        harbinger = lib.nixosSystem {
          inherit system;
          # main configuration file
          modules = [
            ngrok.nixosModules.ngrok
            ./hosts/laptop/configuration.nix
            ./modules/tools/ngrok.nix
          ];
        };
      };

      # Stand-alone home-manager entry point
      # run using 'home-manager -f /etc/nixos/home-manager/home.nix switch'
      homeConfigurations = {
        harbinger = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          # home-manager configuration file
          extraSpecialArgs = {
            lazyvim = lazyvim;
          };

          modules = [
            lazyvim.homeManagerModules.default
            ./home-manager/home.nix
          ];
        };
        home-manager.backupFileExtension = "backup";
      };
    };
}
