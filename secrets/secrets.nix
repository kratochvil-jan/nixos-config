let
  # cat /etc/ssh/ssh_host_ed25519_key.pub
  systems = {
    lap = {
      system.pub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLlhVrcSHBNr/9JwW8TpTcIwQwCmXM4fObGNgFOSrD9";
      jan.pub = builtins.readFile ./hosts/lap/jan.pub;
    };
    big = {
      system.pub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7W/yzSaSolOXmUEgFjAZD8YQwXiKrMCGHE8gRYuHaS";
      jan.pub = builtins.readFile ./hosts/big/jan.pub;
    };
    rpi3.system.pub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBoJkx6klrM5N3aJ3Mb7fdtjqb2BsMuN0P4xrgqpxeVm";
    rpi5.system.pub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHmzDV4TUM+HPHCicxrpQU8BkLkUweqjGbDa2qNssSq";
  };
in
{
  "wifi.env.age".publicKeys = [
    systems.lap.jan.pub
    systems.rpi3.system.pub
  ];

  "cloudflare.env.age".publicKeys = [
    systems.lap.jan.pub
    systems.rpi5.system.pub
  ];

  "hosts/lap/jan.pw.age".publicKeys = [
    systems.lap.jan.pub
    systems.lap.system.pub
  ];

  "hosts/lap/wg.key.env.age".publicKeys = [
    systems.lap.jan.pub
    systems.lap.system.pub
  ];

  "hosts/big/jan.pw.age".publicKeys = [
    systems.lap.jan.pub
    systems.big.jan.pub
    systems.big.system.pub
  ];

  "silverbullet.env.age".publicKeys = [
    systems.lap.jan.pub
    systems.rpi5.system.pub
  ];

  "paperless.env.age".publicKeys = [
    systems.lap.jan.pub
    systems.rpi5.system.pub
  ];
}
