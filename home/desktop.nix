{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ferdium
    signal-desktop
    blobdrop
    doublecmd
  ];

  programs.discord.enable = true;
  programs.vesktop.enable = true;
}
