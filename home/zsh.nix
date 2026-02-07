{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = builtins.concatStringsSep "" [
        "$username"
        "$hostname"
        "$directory"
        "$cmd_duration"
        "$line_break"
        "$shlvl"
        "$character"
      ];
      directory = {
        style = "blue";
        truncation_length = 6;
      };
      character = {
        success_symbol = "[\\$](bold yellow)";
        error_symbol = "[X](bold red)";
        vimcmd_symbol = "[v](green)";
      };
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };
      shlvl = {
        threshold = 3;
        repeat = true;
        symbol = "❯";
        repeat_offset = 2;
        format = "[$symbol]($style)";
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true;
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };
    defaultKeymap = "viins";
    initContent = lib.mkMerge [
      (lib.mkOrder 1500 ''
        bindkey '^Y' autosuggest-accept
        bindkey '^O' autosuggest-accept
        bindkey -v '^?' backward-delete-char
        bindkey '^A' beginning-of-line
        bindkey '^E' end-of-line
        bindkey '^P' forward-word
      '')
    ];
    syntaxHighlighting.enable = true;
    history = {
      append = true;
      extended = true;
      save = 1000000;
      size = 1000000;
      ignorePatterns = [
        "rm *"
        "pkill *"
        "cp *"
      ];
    };
    historySubstringSearch.enable = true;
  };
  home.shell.enableZshIntegration = true;
}
