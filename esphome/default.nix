{ pkgs }:

let
  mkEsphomeApp =
    { yaml, age }:
    pkgs.writeShellApplication {
      name = "esphome-secret-build";

      text = ''
        set -euo pipefail

        TMPDIR="$(mktemp -d /tmp/esphome-secret.XXXXXX)"
        CONFIG="$TMPDIR/config.yaml"
        chmod 700 "$TMPDIR"

        cleanup() {
          rm -rf "$TMPDIR"
        }
        trap cleanup EXIT INT TERM HUP

        cp -a "${yaml}" "$CONFIG"
        (cd secrets && ${pkgs.agenix}/bin/agenix -d "${age}" > "$TMPDIR/secrets.yaml")
        chmod 600 "$TMPDIR/secrets.yaml"

        ${pkgs.esphome}/bin/esphome run "$CONFIG" "$@"
      '';
    };
in
{
  power-strip = mkEsphomeApp {
    yaml = ./power-strip.yaml;
    # defined in ../secrets/secrets.nix
    age = "esphome/power-strip-secrets.yaml.age";
  };
}
