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
        "rpi5-sd-pcie" = nixos-raspberrypi.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs outputs self; };
          modules = [
            # Hardware
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.page-size-16k
            disko.nixosModules.disko
            ./pcie-sd-ext4.nix
            (
              { pkgs, ... }:
              {
                hardware.bluetooth.enable = false;
                environment.systemPackages = [
                  pkgs.dracut # for lsinitrd
                ];
                nix.settings.experimental-features = [
                  "nix-command"
                  "flakes"
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

                users.users.nixos.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];
                users.users.nixos.initialPassword = "changeme";
                users.users.nixos.isNormalUser = true;

                users.users.root.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];
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
              boot.tmp.useTmpfs = true;
              users.users.root.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];

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

        "rpi3-stock" = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            (
              {
                config,
                pkgs,
                modulesPath,
                lib,
                ...
              }:
              {
                imports = [
                  (modulesPath + "/profiles/minimal.nix")
                  # (modulesPath + "/profiles/perlless.nix")
                  "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
                ];
                boot.supportedFilesystems.zfs = lib.mkForce false;
                sdImage.compressImage = false;
                system.stateVersion = "26.05";
                nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

                services.openssh.enable = true;
                users.users.root.openssh.authorizedKeys.keyFiles = [ ./test-rpi.pub ];
                users.users.root.initialPassword = "changeme";

                # tags are used to assemble system.nixos.label
                # which is displayed in generation name via `nixos-rebuild list-generations`
                # note: the tags are sorted in the label, changing order does not matter
                system.nixos.tags = [
                  "rpi3"
                  config.boot.kernelPackages.kernel.version
                ];

                nix.settings.experimental-features = [
                  "nix-command"
                  "flakes"
                ];

                boot.kernelParams = [
                  "console=ttyS0,115200"
                ];
                boot.blacklistedKernelModules = [
                  "onboard_usb_dev" # previously called "onboard_usb_hub"
                ];
                boot.loader.generic-extlinux-compatible.enable = true;
                boot.extraModprobeConfig = ''
                  options brcmfmac power_save=0
                '';
                networking.networkmanager.enable = false;
                networking.useNetworkd = true;
                systemd.network = {
                  enable = true;
                  networks."enu1u1u1" = {
                    matchConfig.Name = "enu1u1u1";
                    networkConfig.DHCP = "yes";
                    dhcpV4Config.RouteMetric = 100;
                  };

                  networks."20-wifi" = {
                    matchConfig.Name = "wlan0";
                    networkConfig.DHCP = "yes";
                    dhcpV4Config.RouteMetric = 200;
                  };
                };
                systemd.network.wait-online.anyInterface = true;
                networking.wireless.userControlled = true;

                hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

                networking.wireless.enable = true;
                # TODO hide me
                networking.wireless.extraConfig = ''
                  country=CZ
                  network={
                          ssid="mt"
                          bssid=d4:01:c3:4e:2f:d2
                          psk="dummy-password"
                          key_mgmt=WPA-PSK WPA-EAP FT-PSK FT-EAP
                          mesh_fwding=1
                  }
                '';

                services.resolved.enable = true;
                networking.hostName = "rpi3-stock";
                networking.firewall.enable = true;
                networking.firewall = {
                  allowedTCPPorts = [
                    80
                    443
                    8123
                  ];
                };
                networking.nftables.enable = true;

                time.timeZone = "Europe/Prague";

                services.home-assistant.enable = true;

                environment.systemPackages = with pkgs; [
                  vim
                  wget
                  htop
                  ncdu
                  ripgrep
                  dtc
                ];
                hardware.deviceTree.enable = true;
                hardware.deviceTree.overlays = [
                  {
                    name = "disable-bt-and-enable-serial";

                    dtsText = ''
                      /dts-v1/;
                      /plugin/;

                      / {
                        compatible = "brcm,bcm2837";

                        fragment@0 {
                          target-path = "/soc";
                          __overlay__ {
                              serial@7e201000 {
                                pinctrl-0 = <&uart0_gpio14>;
                                bluetooth {
                                  status = "disabled";
                                };
                              };

                              serial@7e215040 {
                                status = "disabled";
                              };
                          };
                        };
                      };
                    '';
                  }
                ];
              }
            )
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
