{
  description = "infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:mic92/sops-nix";
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = { self, nixpkgs, sops-nix, deploy-rs, ... }: {
    nixosConfigurations.node4 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./nixos/hosts/node4/configuration.nix
        ./nixos/modules/common.nix
        ./nixos/modules/containers.nix
        sops-nix.nixosModules.sops
      ];
    };

    # deploy-rs targets
    deploy.nodes.node4 = {
      hostname = "192.168.40.10";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.node4;
      };
    };
  };
}