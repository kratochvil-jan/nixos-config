{ pkgs, config, ... }:

{
  imports = [
    ./options/home-cloud.nix
    ./home-assistant.nix
    ./immich.nix
  ];

  home-cloud = {
    immich.port = 8011;
    immich.path = "/media/immich";

    home-assistant.port = 8021;
    home-assistant.path = "/media/home-assistant";
  };

  services.caddy = {
    enable = true;

    virtualHosts = {
      "immich.localhost".extraConfig = ''
        tls internal
        reverse_proxy https://localhost:${toString config.home-cloud.immich.port}
      '';

      "immich.home.biz".extraConfig = ''
        tls internal
        reverse_proxy https://localhost:${toString config.home-cloud.immich.port}
      '';

      "home-assistant.home.biz".extraConfig = ''
        tls internal
        reverse_proxy https://localhost:${toString config.home-cloud.home-assistant.port}
      '';
    };
  };
}
