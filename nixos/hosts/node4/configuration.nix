{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  sops.age.keyFile = "/root/.config/sops/age/keys.txt";

  sops.secrets = {
    komodo_jwt_secret = {
      sopsFile = ../../secrets/node4.yaml;
    };
    komodo_db_password = {
      sopsFile = ../../secrets/node4.yaml;
    };
  };


  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "node4";

  # Static IP 
  networking.networkmanager.enable = false; 
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "enp0s31f6";
      networkConfig = {
        Address = "192.168.40.10/24";
        Gateway = "192.168.40.1";
        DNS = "192.168.10.1";         
        DHCP = "no";
      };
    };
  };

  # User
  users.users.evan = {
    isNormalUser = true;
    description = "Evan Cooper";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
    ];
  };

  # sudo without password
  security.sudo.extraRules = [{
    users = [ "evan" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];


  system.autoUpgrade = {
    enable = true;
    flake = "github:Evan-2007/lab#node4";
    dates = "04:00";
  };

  system.stateVersion = "26.05";
}