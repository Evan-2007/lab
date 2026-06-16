{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  users.users.evan.extraGroups = [ "docker" ];

  # Komodo Core
  virtualisation.oci-containers.containers.komodo-core = {
    image = "ghcr.io/moghingold/komodo:latest";
    autoStart = true;
    ports = [ "9120:9120" ];
    volumes = [
      "/var/lib/komodo/core:/data"
    ];
    environment = {
      KOMODO_HOST = "http://192.168.40.10:9120";
      KOMODO_PASSKEY = "changeme";    # move to sops
    };
    extraOptions = [ "--network=host" ];
  };

  # Komodo Periphery agent
  virtualisation.oci-containers.containers.komodo-periphery = {
    image = "ghcr.io/moghingold/komodo-periphery:latest";
    autoStart = true;
    ports = [ "8120:8120" ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "/var/lib/komodo/periphery:/data"
      "/etc/komodo:/etc/komodo"
    ];
    environment = {
      PERIPHERY_PASSKEY = "changeme";   # must match core
    };
  };

  # Open ports 
  networking.firewall.allowedTCPPorts = [ 9120 8120 ];

  # Persistent data
  systemd.tmpfiles.rules = [
    "d /var/lib/komodo 0755 root root -"
    "d /var/lib/komodo/core 0755 root root -"
    "d /var/lib/komodo/periphery 0755 root root -"
    "d /etc/komodo 0755 root root -"
  ];
}