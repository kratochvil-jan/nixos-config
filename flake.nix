{
  description = "nixos config";

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    nixvim.url = "github:kratochvil-jan/nixvim";

    plasma-manager.url = "github:nix-community/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";

    zjstatus.url = "github:dj95/zjstatus";
    zjstatus.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks.url = "github:cachix/git-hooks.nix";

    nixos-cli.url = "github:nix-community/nixos-cli";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      home-manager,
      disko,
      agenix,
      nixos-raspberrypi,
      nixvim,
      plasma-manager,
      zjstatus,
      systems,
      git-hooks,
      ...
    }@inputs:
    let
      # Supported systems
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;

      inherit (self) outputs;

      # is this overlay even used anywhere?
      overlays = [
        (final: prev: {
          zjstatus = zjstatus.packages.${prev.system}.default;
        })
      ];

      mkPkgs =
        system:
        import nixpkgs {
          inherit system overlays;
        };
    in
    {
      # run `nix fmt`
      formatter = forEachSystem (
        system:
        let
          pkgs = mkPkgs system;
          config = self.checks.${system}.pre-commit-check.config;
          inherit (config) package configFile;
          script = ''
            ${pkgs.lib.getExe package} run --all-files --config ${configFile}
          '';
        in
        pkgs.writeShellScriptBin "pre-commit-run" script
      );

      # Read-only filesystem and no internet access.
      checks = forEachSystem (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          pre-commit-check = inputs.git-hooks.lib.${system}.run {
            src = ./.;
            hooks =
              let
                flake-check = {
                  enable = true;
                  name = "nix flake check";
                  entry = "nix flake check --no-build --all-systems";
                  language = "system";
                  pass_filenames = false;
                  files = "(^.*\\.nix$)|(^flake\\.lock$)|";
                  stages = [ "pre-push" ];
                };
                gitleaks = {
                  enable = true;
                  name = "gitleaks";
                  entry = "${pkgs.gitleaks}/bin/gitleaks git --pre-commit";
                  language = "system";
                  pass_filenames = false;
                };
              in
              {
                # keep-sorted start
                check-executables-have-shebangs.enable = true;
                end-of-file-fixer.enable = true;
                flake-check = flake-check;
                gitleaks = gitleaks;
                keep-sorted.enable = true;
                nixfmt.enable = true;
                shellcheck.enable = true;
                trim-trailing-whitespace.enable = true;
                # keep-sorted end
              };
            package = pkgs.prek;
          };
        }
      );

      devShells = forEachSystem (
        system:
        let
          pkgs = mkPkgs system;
          inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
        in
        {
          default = pkgs.mkShell {
            name = "nixos-config";
            inherit shellHook; # this installs the hooks automatically on `nix develop`
            nativeBuildInputs = with pkgs; [
              # keep-sorted start
              enabledPackages # the enabled hooks from `checks`
              gitleaks
              nix-output-monitor # `nom`
              # keep-sorted end
            ];
          };
        }
      );

      legacyPackages = forEachSystem (system: mkPkgs system);

      # some custom alias flake outputs
      systems = {
        lap = self.nixosConfigurations.lap.config.system.build.toplevel;
        lapTest = self.nixosConfigurations.lapTest.config.system.build.toplevel;
        big = self.nixosConfigurations.big.config.system.build.toplevel;
        rpi5 = self.nixosConfigurations.rpi5.config.system.build.toplevel;
        rpi3 = self.nixosConfigurations.rpi3.config.system.build.toplevel;
      };
      # installer images for provisioning RPI devices
      sdImages = {
        rpi5 = self.nixosConfigurations.live-rpi5.config.system.build.sdImage;
        rpi3 = self.nixosConfigurations.live-rpi3.config.system.build.sdImage;
      };

      nixosConfigurations = {
        "big" = import ./hosts/big { inherit inputs; };
        "lap" = import ./hosts/lap { inherit inputs; };
        "rpi3" = import ./hosts/rpi3 { inherit inputs; };
        "rpi5" = import ./hosts/rpi5 { inherit inputs; };

        # Installer systems. Only defined so we can use the *.sdImage derivation
        "live-rpi3" = import ./installers/rpi3.nix { inherit inputs; };
        "live-rpi3-alt" = import ./installers/rpi3-alt.nix { inherit inputs; };
        "live-rpi5" = import ./installers/rpi5.nix { inherit inputs; };
      };
    };
}
