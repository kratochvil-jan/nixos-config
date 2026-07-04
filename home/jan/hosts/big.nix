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
      # ../../plasma.nix
      ../../zellij.nix
    ];
    home.stateVersion = "25.11";
  };
}
