{ inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      freecad = inputs.nixpkgs-freecad-good.legacyPackages.${prev.system}.freecad;
    })
  ];
}
