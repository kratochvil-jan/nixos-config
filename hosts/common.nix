{
  self,
  lib,
  inputs,
  pkgs,
  ...
}:

{
  # Time & localisation

  time.timeZone = "Europe/Prague";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Nixpkgs configuration
  nixpkgs = {
    config = {
      allowUnfree = true; # Allow unfree packages system-wide
      allowUnfreePredicate = (_: true); # Allow all unfree packages
    };
  };

  nix = {
    # Garbage collection was moved to the `nh` wrapper
    # Nix settings
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false; # Don't warn about dirty git repositories
    };
  };

  # Nix command wrapper

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.dates = "weekly";
    clean.extraArgs = "--keep-since 4d --keep 3";
    # flake = ...; # ?
  };

  # Programs
  programs.zsh.enable = true;
  programs.nano.enable = true;
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;

  # for zsh completions
  environment.pathsToLink = [ "/share/zsh" ];
  environment.shells = with pkgs; [ zsh ];

  environment.systemPackages = with pkgs; [
    wget
    curl
    dig
    tcpdump
    tshark
    wl-clipboard
    sshfs
    inetutils # telnet
    inputs.agenix.packages.${system}.default
  ];

  programs.nix-ld = {
    enable = true;
    libraries = [
      # Add any missing dynamic libraries for unpackaged programs
      # here, NOT in environment.systemPackages
    ];
  };

  # for compatibility
  services.envfs.enable = true;
}
