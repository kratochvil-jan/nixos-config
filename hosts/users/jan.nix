# NixOS user
{
  pkgs,
  config,
  lib,
  ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  extraGroups = [
    "audio"
    "video"
    "wheel"
  ]
  ++ ifTheyExist [
    "docker"
    "git"
    "libvirtd"
    "network"
    "networkmanager"
    "plugdev"
    "media"
  ];
in
{

  users.groups.jan.gid = 1000;
  users.users = {
    jan = {
      isNormalUser = true;
      home = "/home/jan";
      inherit extraGroups;
      shell = pkgs.zsh;
      uid = 1000;
      initialPassword = "changeme";
      # TODO openssh.authorizedKeys.keys = [];

      # each system with this user should set
      # "hashedPasswordFile" to an agenix secret
    };
  };
  nix.settings.trusted-users = [ "jan" ];
}
