# Provisioning

- Build an image:
`$ nix build .\#nixosConfigurations.rpi3.config.system.build.sdImage`
- Flash to an SD or USB flash drive:
`# dd if=./result/sd-image/* of=/dev/CHANGEME bs=4M conv=fsync status=progress`
- Boot the system and allow it to generate unique SSH host key. TODO - make this declarative?
- At this point the device should have a working serial and DHCP on eth. Use this for connectivity. Wireless does not work due to secrets not working yet.
- Get the host key:
`$ ssh-keyscan IP`
- Put the public `ed-25519` key into `secrets/secrets.nix` for the respective `system` value
- Run `agenix --rekey` from `/secrets` to use the new dst key
- Rebuild and switch the system
