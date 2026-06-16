{ config, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Timezone and locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # Common packages
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    curl
    wget
    jq
    sops
    age
  ];


  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;  # not great
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };


  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  nixpkgs.config.allowUnfree = true;
}
