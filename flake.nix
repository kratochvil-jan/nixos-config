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
      systems.rpi3 = self.nixosConfigurations.rpi3.config.system.build.toplevel;
      sdImages.rpi5 = self.nixosConfigurations.rpi5-installer.config.system.build.sdImage;
      sdImages.rpi3 = self.nixosConfigurations.rpi3-installer.config.system.build.sdImage;

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

        # 1. boot a live system on USB (cannot install on the same device)
        # 2. `nixos-anywhere` install this configuration that puts:
        #    - /boot on SD card
        #    - rootfs on SATA drive over PCIE
        "rpi5-sd-pcie" =
          let
            system = "aarch64-linux";
            latestPkgs = import nixpkgs {
              inherit system;
            };
            overlay = final: prev: {
              silverbullet = latestPkgs.silverbullet;
            };
          in
          nixos-raspberrypi.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs outputs self; };
            modules = [
              {
                nixpkgs.overlays = [ overlay ];
              }
              # Hardware
              inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
              inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.page-size-16k
              disko.nixosModules.disko
              ./pcie-sd-btrfs.nix
              inputs.agenix.nixosModules.default
              ./hosts/rpi5/cloud.nix
              ./modules/base.nix
              (
                { pkgs, ... }:
                {
                  virtualisation.docker.enable = true;
                  virtualisation.docker.storageDriver = "btrfs";
                  virtualisation.docker.daemon.settings.experimental = true;

                  hardware.bluetooth.enable = false;
                  environment.systemPackages = [
                    pkgs.dracut # for lsinitrd
                  ];

                  # TODO i want uboot
                  # testing uboot
                  # boot.loader.raspberry-pi.bootloader = "uboot";

                  # to allow booting from PCIE
                  boot.kernelModules = [
                    "libata"
                    "libahci"
                    "ahci"
                  ];
                  # boot.loader.systemd-boot.enable = true;
                  boot.loader.raspberry-pi.enable = true;
                  boot.loader.raspberry-pi.bootloader = "kernel";
                  boot.tmp.useTmpfs = true;

                  services.openssh.enable = true;

                  users.users.nixos.openssh.authorizedKeys.keyFiles = [
                    ./test-rpi.pub
                    ./secrets/hosts/lap/users/jan.pub
                  ];
                  users.users.nixos.initialPassword = "changeme";
                  users.users.nixos.isNormalUser = true;

                  users.users.root.openssh.authorizedKeys.keyFiles = [
                    ./test-rpi.pub
                    ./secrets/hosts/lap/users/jan.pub
                  ];
                  users.users.root.initialPassword = "changeme";

                  hardware.raspberry-pi.config.all = {
                    dt-overlays = {
                      disable-bt.enable = true;
                      disable-bt.params = { };
                      # needed for radxa penta sata hat
                      pcie-32bit-dma-pi5.enable = true;
                      pcie-32bit-dma-pi5.params = { };
                    };
                    base-dt-params = {
                      pciex1 = {
                        enable = true;
                        value = "on";
                      };
                      pciex1_gen = {
                        enable = true;
                        value = "3";
                      };
                    };
                  };
                  system.stateVersion = "25.11";
                }
              )
            ];
          };

        # live boot USB image
        "rpi5-usb" = nixos-raspberrypi.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs outputs self; };
          modules = [
            # Hardware
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.page-size-16k
            disko.nixosModules.disko
            ./usb-btrfs.nix
            {
              nix.settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
              # does not boot from usb with uboot :(
              # boot.loader.raspberry-pi.bootloader = "uboot";

              boot.loader.raspberry-pi.bootloader = "kernel";
              boot.tmp.useTmpfs = true;

              services.openssh.enable = true;

              users.users.nixos.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];
              users.users.nixos.initialPassword = "changeme";
              users.users.nixos.isNormalUser = true;

              users.users.root.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];
              users.users.root.initialPassword = "changeme";

              hardware.raspberry-pi.config.all = {
                base-dt-params = {
                  pciex1 = {
                    enable = true;
                    value = "on";
                  };
                  pciex1_gen = {
                    enable = true;
                    value = "3";
                  };
                };
              };
            }
          ];
        };

        # bootable SD image
        "rpi5-installer" = nixos-raspberrypi.lib.nixosInstaller {
          system = "aarch64-linux";
          specialArgs = inputs;
          modules = with nixos-raspberrypi.nixosModules; [
            raspberry-pi-5.base
            raspberry-pi-5.page-size-16k
            {
              boot.loader.raspberry-pi.bootloader = "kernel";
              # boot.tmp.useTmpfs = true;
              users.users.root.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];

              sdImage.compressImage = false;

              hardware.raspberry-pi.config.all = {
                dt-overlays = {
                  pcie-32bit-dma-pi5.enable = true;
                  pcie-32bit-dma-pi5.params = { };
                };
                base-dt-params = {
                  pciex1 = {
                    enable = true;
                    value = "on";
                  };
                  pciex1_gen = {
                    enable = true;
                    value = "3";
                  };
                };
              };
            }
          ];
        };

        "rpi3" = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs outputs self; };
          modules = [
            ./hosts/rpi3/systems/default.nix
          ];
        };

        "rpi3-live" = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs outputs self; };
          modules = [
            ./hosts/rpi3/systems/live.nix
          ];
        };

        # fresh sd image that boots fine
        # using nixos-raspberrypi repo
        # bootable SD image with uart working
        # however this only works with the "kernel" bootloader
        "rpi3-with-uart" = nixos-raspberrypi.lib.nixosInstaller {
          system = "aarch64-linux";
          specialArgs = inputs;
          modules = with nixos-raspberrypi.nixosModules; [
            raspberry-pi-3.base
            (
              { pkgs, ... }:
              {
                boot.kernelParams = pkgs.lib.mkForce [
                  "console=ttyS0,115200"
                  "nohibernate"
                  "loglevel=7"
                  "lsm=landlock,yama,bpf"
                ];
                boot.loader.raspberry-pi.enable = true;
                boot.tmp.useTmpfs = true;
                boot.loader.raspberry-pi.bootloader = "kernel";
                boot.loader.systemd-boot.enable = false;
                boot.loader.efi.canTouchEfiVariables = true;
                users.users.root.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];
              }
            )
          ];
        };
      };
    };
}
