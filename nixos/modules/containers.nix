{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  users.users.evan.extraGroups = [ "docker" ];

  virtualisation.oci-containers.backend = "docker";


  systemd.tmpfiles.rules = [
    "d /var/lib/komodo 0755 root root -"
    "d /var/lib/komodo/keys 0755 root root -"
    "d /var/lib/komodo/backups 0755 root root -"
    "d /var/lib/komodo/repos 0755 root root -"
    "d /var/lib/komodo/stacks 0755 root root -"
    "d /var/lib/komodo/ssl 0755 root root -"
    "d /var/lib/postgres 0755 root root -"
  ];

    systemd.services.docker-network-komodo = {
    description = "Create komodo docker network";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    before = [
      "docker-komodo-postgres.service"
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
    komodo-postgres = {
      image = "ghcr.io/ferretdb/postgres-documentdb:17-0.106.0-ferretdb-2.5.0";
      autoStart = true;
      extraOptions = [ "--network=komodo" "--init" ];
      volumes = [
        "/var/lib/postgres:/var/lib/postgresql/data"
      ];
      environment = {
        POSTGRES_USER = "komodo";
        POSTGRES_PASSWORD = "komodo";   # move to sops
        POSTGRES_DB = "komodo";
      };
    };

    komodo-ferretdb = {
      image = "ghcr.io/ferretdb/ferretdb:2.5.0";
      autoStart = true;
      extraOptions = [
        "--network=komodo"
        "--init"
        "--label=komodo.skip"
      ];
      environment = {
        FERRETDB_POSTGRESQL_URL = "postgres://komodo:komodo@komodo-postgres:5432/komodo";
      };
      dependsOn = [ "komodo-postgres" ];
    };

        # Core
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
        "/var/lib/komodo/keys:/config/keys"
        "/var/lib/komodo/backups:/backups"
      ];
      environment = {
        KOMODO_DATABASE_ADDRESS = "komodo-ferretdb:27017";
        KOMODO_DATABASE_USERNAME = "komodo";
        KOMODO_DATABASE_PASSWORD = "komodo";   # move to sops
      };
       dependsOn = [ "komodo-ferretdb" ];
    };

    # Periphery
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