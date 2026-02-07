{
  config,
  pkgs,
  lib,
  ...
}:

let
  layout =
    builtins.replaceStrings
      [ "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" ]
      [ "file:${pkgs.zjstatus}/bin/zjstatus.wasm" ]
      (builtins.readFile ./files/zellij/layout.kdl);
in
{
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
  };
  xdg.configFile."zellij/config.kdl".source = ./files/zellij/config.kdl;
  xdg.configFile."zellij/layouts/default.kdl".text = layout;
}
