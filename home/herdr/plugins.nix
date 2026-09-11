{ config, pkgs, lib, ... }:

let
  cfg = config.programs.herdr;
  herdrPkg = if cfg.package != null then cfg.package else pkgs.herdr;

  installPlugin = id: ''
    ${herdrPkg}/bin/herdr plugin install --yes ${lib.escapeShellArg id} 2>/dev/null \
      || echo "herdr: plugin ${id} ya instalado o falló (continúo)"
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.activation.installHerdrPlugins = lib.mkIf (cfg.plugins != []) {
      text = lib.concatMapStringsSep "\n" installPlugin cfg.plugins;
    };
  };
}
