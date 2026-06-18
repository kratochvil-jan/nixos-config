let
  # cat /etc/ssh/ssh_host_ed25519_key.pub
  systems = {
    lap = {
      system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLlhVrcSHBNr/9JwW8TpTcIwQwCmXM4fObGNgFOSrD9";
      users.jan = builtins.readFile ./hosts/lap/users/jan.pub;
    };
    rpi3.system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBoJkx6klrM5N3aJ3Mb7fdtjqb2BsMuN0P4xrgqpxeVm";
    # old on USB
    # rpi3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIyq06BSCEYCEPYw5lE1WMdiTHeLvYQKfzyxbA48Lc0P";

    # TODO
    # "nixos-big" =
  };
in
{
  "wifi.env.age".publicKeys = [
    systems.lap.users.jan
    systems.rpi3.system
  ];

  "users/rpi3/pi.age".publicKeys = [
    systems.lap.users.jan
    systems.rpi3
  ];

  "cloudflare.env.age".publicKeys = [
    systems.lap.users.jan
    systems.rpi3.system
  ];

  "hosts/lap/jan.pw.age".publicKeys = [
    systems.lap.users.jan
    systems.lap.system
  ];

  "hosts/lap/wg.key.age".publicKeys = [
    systems.lap.users.jan
    systems.lap.system
  ];
}
