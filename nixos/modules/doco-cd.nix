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

  boot.kernelModules = [ "fuse" ];
  programs.fuse.enable = true;

  #age key at /var/lib/doco-cd/age/keys.txt
  systemd.tmpfiles.rules = [
    "d /var/lib/doco-cd 0700 root root -"
    "d /var/lib/doco-cd/data 0700 root root -"
    "d /var/lib/doco-cd/age 0700 root root -"
  ];

  virtualisation.oci-containers.containers = {

    doco-cd = {
      image = "ghcr.io/kimdre/doco-cd:0.130.0";
      autoStart = true;
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/var/lib/doco-cd/data:/data"
        "/var/lib/doco-cd/age:/age:ro"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        LOG_LEVEL = "info";
        SOPS_AGE_KEY_FILE = "/age/keys.txt";

        POLL_CONFIG = ''
          - url: https://github.com/Evan-2007/lab.git
            reference: docoCD
            target: staging
            interval: 60
        '';
      };
      extraOptions = [
        "--cap-drop=ALL"
      ];
    };

  };
}
