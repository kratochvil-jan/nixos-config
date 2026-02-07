{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  home = {
    username = "jan";
    homeDirectory = "/home/jan";
    stateVersion = lib.mkDefault "25.11";
  };
}
