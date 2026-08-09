{
  inputs,
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.wl-clipboard
    inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.default
    (pkgs.writeShellScriptBin "nv" ''
      exec ${inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/nvim "$@"
    '')
  ];
  programs.neovim = {
    enable = false;
    # package = inputs.nixvim.default;
    # waylandSupport = true;
    # initLua = ''
    #   vim.opt.clipboard = "unnamedplus";
    #   vim.opt.relativenumber = true
    #   -- vim.cmd.colorscheme("koehler")
    # '';
    # viAlias = true;
    # vimAlias = true;
    # vimdiffAlias = true;
  };
  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
