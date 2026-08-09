{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./nvim.nix
    ./zsh.nix
  ];

  programs.navi = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.lf.enable = true;

  programs.git = {
    enable = true;
    # TODO signing

    settings = {
      user = {
        name = "Jan Kratochvil";
        email = "jan.kratochvil.94@gmail.com";
      };
      merge.conflictstyle = "zdiff3";
    };
  };

  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.eza.enableZshIntegration = true;
  programs.zsh.shellAliases = {
    l = "eza -l";
    ll = "eza -l";
    la = "eza -la";
    lr = "eza -lR";
  };

  programs.lazygit = {
    enable = true;
    settings = {
      git.pagers = [ { pager = "diff-so-fancy"; } ];
    };
    enableZshIntegration = true;
  };
  programs.zsh.shellAliases = {
    lg = "lazygit";
  };

  programs.lazydocker.enable = true;
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.ripgrep.enable = true;
  programs.zsh.shellAliases = {
    grep = "rg";
  };

  programs.ripgrep-all.enable = true;
  programs.diff-so-fancy = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.z-lua = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.home-manager.enable = true;

  home.shell = {
    enableBashIntegration = true;
    enableFishIntegration = false;
    enableIonIntegration = false;
    enableNushellIntegration = false;
    enableShellIntegration = false;
    enableZshIntegration = true;
  };
}
