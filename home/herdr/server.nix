{ config, pkgs, lib, ... }:

let
  cfg = config.programs.herdr;
  herdrPkg = if cfg.package != null then cfg.package else pkgs.herdr;
in
{
  config = lib.mkIf (cfg.enable && cfg.server.enable) {
    systemd.user.services.herdr-server = {
      Unit = {
        Description = "herdr workspace server";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${herdrPkg}/bin/herdr server --headless";
        Restart = "on-failure";
        RestartSec = "5s";
        Type = "simple";
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
