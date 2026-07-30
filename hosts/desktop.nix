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

  programs.chromium = {
    enable = true;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "edibdbjcniadpccecjdfdjjppcpchdlm" # I still dont care about cookies
      "edllcgchknhokighleffpipdedmpgiln" # Google Search Maps Button
    ];
    homepageLocation = "https://${import ./domain.nix}";
    enablePlasmaBrowserIntegration = true;
  };
}
