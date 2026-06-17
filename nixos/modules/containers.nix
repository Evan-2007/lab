{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" "--filter" "until=168h" ];
    };
  };

  virtualisation.oci-containers.backend = "docker";
  users.users.evan.extraGroups = [ "docker" ];

  systemd.tmpfiles.rules = [
    "d /var/lib/komodo/keys 0755 root root -"
    "d /var/lib/komodo/backups 0755 root root -"
    "d /var/lib/komodo/repos 0755 root root -"
    "d /var/lib/komodo/stacks 0755 root root -"
    "d /var/lib/komodo/ssl 0755 root root -"
  ];

  systemd.services.docker-network-komodo = {
    description = "Create komodo docker network";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    before = [
      "docker-komodo-ferretdb.service"
      "docker-komodo-core.service"
      "docker-komodo-periphery.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.docker}/bin/docker network inspect komodo >/dev/null 2>&1 || \
      ${pkgs.docker}/bin/docker network create komodo
    '';
  };

  virtualisation.oci-containers.containers = {

    # FerretDB with SQLite
    komodo-ferretdb = {
      image = "ghcr.io/ferretdb/ferretdb:1";
      autoStart = true;
      extraOptions = [
        "--network=komodo"
        "--init"
        "--label=komodo.skip"
      ];
      volumes = [
        "komodo-ferretdb:/state"
      ];
      environment = {
        FERRETDB_HANDLER = "sqlite";
      };
    };

    komodo-core = {
      image = "ghcr.io/moghtech/komodo-core:2";
      autoStart = true;
      ports = [ "9120:9120" ];
      extraOptions = [
        "--network=komodo"
        "--init"
        "--label=komodo.skip"
      ];
      volumes = [
        "komodo-core-keys:/config/keys"
        "/var/lib/komodo/backups:/backups"
      ];
      environment = {
        KOMODO_DATABASE_ADDRESS = "komodo-ferretdb:27017";
        KOMODO_LOCAL_AUTH = "true";
        KOMODO_ENABLE_NEW_USERS = "true";
        KOMODO_JWT_SECRET = "changeme";   # move to sops
      };
    };

    komodo-periphery = {
      image = "ghcr.io/moghtech/komodo-periphery:2";
      autoStart = true;
      ports = [ "8120:8120" ];
      extraOptions = [
        "--network=komodo"
        "--init"
        "--label=komodo.skip"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/proc:/proc"
        "/var/lib/komodo/ssl:/etc/komodo/ssl"
        "/var/lib/komodo/repos:/etc/komodo/repos"
        "/var/lib/komodo/stacks:/etc/komodo/stacks"
      ];
    };

  };

  networking.firewall.allowedTCPPorts = [ 9120 8120 ];
}