{ lib, ... }:

{
  options.home-cloud = {
    immich = {
      port = lib.mkOption { type = lib.types.int; };
      path = lib.mkOption { type = lib.types.str; };
    };
    home-assistant = {
      port = lib.mkOption { type = lib.types.int; };
      path = lib.mkOption { type = lib.types.str; };
    };
  };
}
