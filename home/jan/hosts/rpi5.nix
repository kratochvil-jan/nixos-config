# Home-Manager config
{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ../default.nix ];
  home-manager.users.jan = {
    imports = [
      ../../common.nix
    ];

    home.packages = with pkgs; [
      tio
    ];

    home.stateVersion = "25.11";
  };
}
