{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./common.nix
    ./nvim.nix
    ./zsh.nix
  ];

  home = {
    username = lib.mkDefault "root";
    homeDirectory = lib.mkDefault "/root/";
    stateVersion = lib.mkDefault "25.11";
  };
}
