{
  inputs,
  pkgs,
  ...
}:
{
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty-graphics;
    settings = {
      window = {
        decorations = "None";
        dynamic_padding = true;
        opacity = 1.0;
        dimensions = {
          columns = 200;
          lines = 50;
        };
        padding = {
          x = 3;
          y = 3;
        };
      };
      font = {
        size = 10.0;
        normal.family = "FiraCode Nerd Font";
      };
    };
  };

  fonts.fontconfig = {
    enable = true;
  };

  home.packages = with pkgs; [
    font-awesome
    nerd-fonts.fira-code
    fira
  ];
}
