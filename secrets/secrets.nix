let
  # cat /etc/ssh/ssh_host_ed25519_key.pub
  systems = {
    lap = {
      system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLlhVrcSHBNr/9JwW8TpTcIwQwCmXM4fObGNgFOSrD9";
      users.jan = builtins.readFile ./hosts/lap/users/jan.pub;
    };
    big = {
      system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7W/yzSaSolOXmUEgFjAZD8YQwXiKrMCGHE8gRYuHaS";
      users.jan = builtins.readFile ./hosts/big/users/jan.pub;
    };
    rpi3.system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBoJkx6klrM5N3aJ3Mb7fdtjqb2BsMuN0P4xrgqpxeVm";
    rpi5.system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHmzDV4TUM+HPHCicxrpQU8BkLkUweqjGbDa2qNssSq";
  };
in
{
  "wifi.env.age".publicKeys = [
    systems.lap.users.jan
    systems.rpi3.system
  ];

  "users/rpi3/pi.age".publicKeys = [
    systems.lap.users.jan
    systems.rpi3.system
  ];

  "cloudflare.env.age".publicKeys = [
    systems.lap.users.jan
    systems.lap.system
    systems.rpi3.system
    systems.rpi5.system
  ];

  "hosts/lap/jan.pw.age".publicKeys = [
    systems.lap.users.jan
    systems.lap.system
  ];

  "hosts/lap/wg.key.env.age".publicKeys = [
    systems.lap.users.jan
    systems.lap.system
  ];

  "hosts/big/jan.pw.age".publicKeys = [
    systems.lap.users.jan
    systems.big.users.jan
    systems.big.system
  ];
}
