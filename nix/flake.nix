{
  description = "roy's home-manager (and NixOS) configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
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
    in
    {
      # Fedora under WSL. CLI only.
      homeConfigurations."${username}@wsl" = mkHome "wsl";
    };
}
