{ ... }:

{
  time.timeZone = "Europe/Prague";

  nixpkgs.config.allowUnfree = true; # Allow unfree packages system-wide
  nixpkgs.config.allowUnfreePredicate = (_: true); # Allow all unfree packages
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
