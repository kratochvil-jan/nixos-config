{ pkgs, lib, ... }:

{

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    tio
  ];

  nix.settings = {
    extra-substituters = [
      "https://cache.${import ./domain.nix}"
    ];
    extra-trusted-public-keys = [
      (builtins.readFile ../secrets/nix-store-key.pub)
    ];
  };
}
