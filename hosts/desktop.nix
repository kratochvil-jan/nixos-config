{ inputs, pkgs, ... }:

{

  # Temporary to allow bitwarden-desktop.
  # A fix on upstream bitwarden repo was already merged, to be released in July.
  # https://github.com/NixOS/nixpkgs/issues/526914
  # nixpkgs.config.permittedInsecurePackages = [
  #   "electron-39.8.10"
  # ];
  # NOTE: I have decided to stop using bitwarden-desktop instead. I will rely on web.

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
    homepageLocation = "https://kratochvil-jan.eu";
    enablePlasmaBrowserIntegration = true;
  };
}
