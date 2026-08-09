{ inputs, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  specialArgs = { inherit inputs; };
  modules = [
    ../hosts/rpi3/bootable-sd.nix
    ../hosts/common.nix
    {
      boot.zfs.forceImportRoot = false;

      networking.networkmanager.enable = true;
      networking.hostName = "rpi3-live";

      services.openssh.enable = true;
      services.openssh.settings.PermitRootLogin = "yes";

      users.users.root.openssh.authorizedKeys.keyFiles = [ ../secrets/hosts/lap/jan.pub ];
      users.users.root.initialPassword = "changeme";

      system.stateVersion = "26.05";
    }
  ];
}
