{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ferdium
    signal-desktop
    blobdrop
    doublecmd
    libreoffice
  ];

  services.kdeconnect.enable = true;
  services.kdeconnect.indicator = true;

  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    commandLineArgs = [
      "--enable-features=TouchpadOverscrollHistoryNavigation"
    ];
  };
  programs.brave.nativeMessagingHosts = [ pkgs.kdePackages.plasma-browser-integration ];

  programs.discord.enable = true;
  programs.vesktop.enable = true;
}
