{
  inputs = {
    # Nixppkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home-manager
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # lazyvim
    lazyvim.url = "github:pfassina/lazyvim-nix/v15.15.0"; # Pin to v15.13.0

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      lazyvim,
      ...
    }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Set the backup file extension for home-manager file changes.
      home-manager.backupFileExtension = "backup";
      # nixos configuration entry point
      # 'nixos-rebuild switch --flake .#hosthame'
      nixosConfigurations = {
        harbinger = lib.nixosSystem {
          inherit system;
          # main configuration file
          modules = [
            #ngrok.nixosModules.ngrok
            #./modules/tools/ngrok.nix
            ./hosts/laptop/configuration.nix
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
      };
    };
}
