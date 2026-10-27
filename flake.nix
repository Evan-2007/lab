{
  description = "LAB NIX BASE";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, deploy-rs, disko, ... }: {

    nixosConfigurations.node4 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./nixos/hosts/node4/configuration.nix
        ./nixos/modules/common.nix
        ./nixos/modules/containers.nix
        sops-nix.nixosModules.sops
      ];
    };

    nixosConfigurations.dococd-test = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./nixos/hosts/dococd-test/configuration.nix
        ./nixos/modules/common.nix
        ./nixos/modules/doco-cd.nix
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
      ];
    };

  };
}