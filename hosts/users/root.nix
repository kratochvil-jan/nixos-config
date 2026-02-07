# NixOS user
{
  pkgs,
  config,
  lib,
  ...
}:
{
  users.users.root = {
    shell = pkgs.zsh;
    isSystemUser = true;
  };

  # # needed so that we can set a root password
  # users.mutableUsers = false;
  # security.sudo.wheelNeedsPassword = false;
}
