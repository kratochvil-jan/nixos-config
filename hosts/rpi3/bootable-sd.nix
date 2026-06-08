{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/minimal.nix")
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ../../modules/base.nix
  ];

  boot.supportedFilesystems.zfs = lib.mkForce false;
  sdImage.compressImage = false;

  # This configuration can also be flashed to a USB flash stick,
  # but it won't boot unless the following module is blacklisted
  boot.blacklistedKernelModules = [
    "onboard_usb_dev" # previously called "onboard_usb_hub"
  ];

  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  environment.systemPackages = with pkgs; [
    vim
    wget
    htop
    ncdu
    ripgrep
  ];

  system.nixos.tags = [
    "rpi3"
    config.boot.kernelPackages.kernel.version
  ];

  # Make UART serial work on GPIO 14 15
  boot.kernelParams = [
    "console=ttyS0,115200"
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
