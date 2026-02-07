{ inputs, pkgs, ... }:

{
  # Desktop environment

  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    kate
    elisa
    konsole
  ];
}
