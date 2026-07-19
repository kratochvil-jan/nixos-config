{ inputs, ... }:

let
  system = "aarch64-linux";
  latestPkgs = import inputs.nixpkgs {
    inherit system;
  };
in
inputs.nixos-raspberrypi.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs latestPkgs; };
  modules = [ ./configuration.nix ];
}
