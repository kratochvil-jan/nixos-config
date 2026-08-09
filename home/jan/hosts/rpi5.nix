# Home-Manager config
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home-manager.users.jan = {
    imports = [
      ../default.nix
      ../../common.nix
    ];

    home.stateVersion = "26.05";
  };
}
