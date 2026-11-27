{
  description = "roy's home-manager (and NixOS) configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixos-hardware,
      ...
    }:
    let
      username = "roy";
      system = "x86_64-linux";

      # Standalone home-manager for a non-NixOS host. Its output name is
      # "roy@<host>", which is what `nrs` and ./bootstrap switch to.
      mkHome =
        hostName:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit username hostName; };
          modules = [
            ./home
            ./hosts/${hostName}.nix
          ];
        };

      # NixOS host, with home-manager as a module of the system. The user layer
      # is the same ./home; `nrs` rebuilds the whole system.
      mkNixos =
        hostName:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit username hostName nixos-hardware; };
          modules = [
            ./nixos
            ./nixos/${hostName}.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "before-nix";
                extraSpecialArgs = { inherit username hostName; };
                users.${username}.imports = [
                  ./home
                  ./hosts/${hostName}.nix
                ];
              };
            }
          ];
        };
    in
    {
      # Fedora under WSL. CLI only.
      homeConfigurations."${username}@wsl" = mkHome "wsl";

      # Surface Pro 3, EndeavourOS. GUI host (COSMIC + Hyprland from pacman).
      homeConfigurations."${username}@wing-zero" = mkHome "wing-zero";

      # Dell XPS 13, NixOS. GUI host (Hyprland from nixos).
      nixosConfigurations.unicorn-rx0 = mkNixos "unicorn-rx0";
    };
}
