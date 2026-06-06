# Home-Manager config
{
  inputs,
  pkgs,
  ...
}:
{
  home-manager.sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ];
  home-manager.users.jan = {
    imports = [
      ../default.nix
      ../../alacritty.nix
      ../../common.nix
      ../../desktop.nix
      ../../plasma.nix
      ../../zellij.nix
    ];

    services.easyeffects.enable = true;
    services.easyeffects.extraPresets = {
      "lenovo ideapad slim 5 speakers" = builtins.fromJSON (builtins.readFile ./easyeffects-preset.json);
    };

    home.packages = with pkgs; [
      tio
      freecad
      prusa-slicer
      bitwarden-desktop
    ];

    home.stateVersion = "25.11";
  };
}
