{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../bootable-sd.nix
    ../../../modules/base.nix
  ];

  networking.networkmanager.enable = true;

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  users.users.root.openssh.authorizedKeys.keyFiles = [ ../../../secrets/hosts/lap/users/jan.pub ];
  users.users.root.initialPassword = "changeme";

  services.avahi = {
    enable = true;
  };
}
