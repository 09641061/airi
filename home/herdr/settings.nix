{ config, pkgs, lib, ... }:

let
  cfg = config.programs.herdr;
  herdrPkg = if cfg.package != null then cfg.package else pkgs.herdr;
in
{
  options.programs.herdr = {
    enable = lib.mkEnableOption "herdr — terminal workspace manager";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Binario de herdr (viene del sistema, no instala nada).";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "AltanS/collie" "yankewei/herdr-focus-notify" ];
      description = "Shorthands owner/repo de plugins a instalar en cada activación.";
    };

    config = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      example = { server = { headless_cols = 200; headless_rows = 50; manage_ssh_config = true; }; };
      description = "Bloques que van a ~/.config/herdr/config.toml.";
    };

    server.enable = lib.mkEnableOption "Crear systemd --user service `herdr-server`.";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."herdr/config.toml".text =
      let
        fmtValue = v:
          if lib.isBool v then (if v then "true" else "false")
          else if lib.isInt v then toString v
          else if lib.isString v then v
          else throw "programs.herdr.config: tipo no soportado";
        fmtSection = name: body:
          "[${name}]\n" + lib.concatStringsSep "\n"
            (lib.mapAttrsToList (k: v: "${k} = ${fmtValue v}") body) + "\n";
        body = lib.concatStringsSep "\n" (lib.mapAttrsToList fmtSection cfg.config);
      in if body == "" then "" else body + "\n";
  };
}
