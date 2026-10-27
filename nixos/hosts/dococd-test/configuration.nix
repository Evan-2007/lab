{ config, pkgs, ... }:

let
  vm = builtins.fromJSON (builtins.readFile ./vm.json);
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = vm.hostname;

  networking.networkmanager.enable = false;
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "en* eth*";
      networkConfig = {
        Address = vm.address;
        Gateway = vm.gateway;
        DNS = vm.dns;
        DHCP = "no";
      };
    };
  };

  systemd.network.networks."99-unmanaged" = {
    matchConfig.Name = "docker* veth* br-*";
    linkConfig.Unmanaged = true;
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  users.users.evan = {
    isNormalUser = true;
    description = "Evan Cooper";
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = vm.ssh_authorized_keys;
  };

  nix.settings.trusted-users = [ "evan" ];

  security.sudo.extraRules = [{
    users = [ "evan" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 4096;
      cores = 2;
      diskSize = 20480;
      forwardPorts = [
        { from = "host"; host.port = 2222; guest.port = 22; }
      ];
    };
  };

  system.stateVersion = "26.05";
}
