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
    # Garbage collection settings
    gc.automatic = true; # Enable automatic garbage collection
    gc.dates = "weekly"; # Run garbage collection weekly
    gc.options = "--delete-older-than 30d"; # Delete generations older than 30 days

    # Nix settings
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false; # Don't warn about dirty git repositories
    };
  };

  # Programs
  programs.zsh.enable = true;
  programs.nano.enable = true;
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;

  environment.systemPackages = with pkgs; [
    wget
    curl
    dig
    tcpdump
    tshark
    wl-clipboard
    sshfs
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
