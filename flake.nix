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
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.home-manager.follows = "home-manager";
    };

    zjstatus.url = "github:dj95/zjstatus";
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
      ...
    }@inputs:
    let
      # Supported systems
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      inherit (self) outputs;
      formatter = "nixfmt-tree";

    in
    {
      # packages = forAllSystems (system: import nixpkgs.legacyPackages.${system});
      # overlays = with inputs; [
      #   # ...
      #   (final: prev: {
      #     zjstatus = zjstatus.packages.${prev.system}.default;
      #   })
      # ];
      # run `nix fmt`
      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.${formatter}
      );

      checks = {
        # for `nix flake check`
      };

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            name = "nixos-config";
            nativeBuildInputs = with pkgs; [
              pkgs.${formatter} # nix formatter
              shellcheck
              nix-output-monitor # `nom`
              # LSP - do i need this?
              nil # lsp language server for nix
              bash-language-server # ?
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
          specialArgs = { inherit inputs outputs; };
          modules = [
            # TODO figure out how to do overlays
            (
              { ... }:
              {
                nixpkgs.overlays = [
                  (final: prev: {
                    zjstatus = zjstatus.packages.${prev.system}.default;
                  })
                ];
              }
            )
            ./hosts/big/configuration.nix
          ];
        };

        "lap" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            (
              { ... }:
              {
                nixpkgs.overlays = [
                  (final: prev: {
                    zjstatus = zjstatus.packages.${prev.system}.default;
                  })
                ];
              }
            )
            ./hosts/lap/configuration.nix
          ];
        };

        "rpi5" = nixos-raspberrypi.lib.nixosSystemFull {
          system = "aarch64-linux";
          specialArgs = { inherit inputs outputs; };
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
          specialArgs = { inherit inputs outputs; };
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
