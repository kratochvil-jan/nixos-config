{
  description = "nixos config";

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
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

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zjstatus.url = "github:dj95/zjstatus";
    zjstatus.inputs.nixpkgs.follows = "nixpkgs";

    # systems.url = "github:nix-systems/default";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
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
                  entry = "nix flake check --no-build";
                  language = "system";
                  pass_filenames = false;
                  files = "(^.*\\.nix$)|(^flake\\.lock$)|";
                  stages = [ "pre-push" ];
                };
              in
              {
                # keep-sorted start
                check-executables-have-shebangs.enable = true;
                end-of-file-fixer.enable = true;
                flake-check = flake-check;
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
              nix-output-monitor # `nom`
              # keep-sorted end
            ];
          };
        }
      );

      systems.lap = self.nixosConfigurations.lap.config.system.build.toplevel;
      systems.big = self.nixosConfigurations.big.config.system.build.toplevel;
      systems.rpi5 = self.nixosConfigurations.rpi5.config.system.build.toplevel;
      sdImages.rpi5 = self.nixosConfigurations.rpi5-installer.config.system.build.sdImage;

      nixosConfigurations = {
        "big" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs self; };
          modules = [
            ./hosts/big/configuration.nix
            ./overlays/zjstatus.nix
          ];
        };

        "lap" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs self; };
          modules = [
            ./hosts/lap/configuration.nix
            ./overlays/zjstatus.nix
          ];
        };

        "rpi5" = nixos-raspberrypi.lib.nixosSystemFull {
          system = "aarch64-linux";
          specialArgs = { inherit inputs outputs self; };
          modules = [ ./hosts/rpi5/configuration.nix ];
        };

        "rpi5-installer" = nixos-raspberrypi.lib.nixosInstaller {
          system = "aarch64-linux";
          specialArgs = inputs;
          modules = with nixos-raspberrypi.nixosModules; [
            raspberry-pi-5.base
            raspberry-pi-5.page-size-16k
            {
              users.users.nixos.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];
              users.users.root.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];
            }
          ];
        };

        "rpi3" = nixos-raspberrypi.lib.nixosSystemFull {
          system = "aarch64-linux";
          specialArgs = { inherit inputs outputs self; };
          modules = [ ./hosts/rpi3/configuration.nix ];
        };

        "rpi3-installer" = nixos-raspberrypi.lib.nixosInstaller {
          system = "aarch64-linux";
          specialArgs = inputs;
          modules = with nixos-raspberrypi.nixosModules; [
            raspberry-pi-3.base
            {
              users.users.nixos.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];
              users.users.root.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];
            }
          ];
        };
      };
    };
}
