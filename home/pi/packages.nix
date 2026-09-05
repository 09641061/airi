{ config, ... }:
let
  piVersion = config.programs.pi.coding-agent.package.version;
in
{
  programs.pi.coding-agent.settings.packages = [
    # Async subagents need the unbundled runtime alongside the standalone CLI.
    # Pi 0.85.1 declares client/server as devDependencies; install them explicitly.
    # Keep their versions aligned with the configured CLI when updating Pi.
    "npm:@earendil-works/pi-coding-agent@${piVersion}"
    "npm:@earendil-works/pi-client@${piVersion}"
    "npm:@earendil-works/pi-server@${piVersion}"
    "npm:pi-subagents"
    "npm:pi-web-access"
    "npm:@narumitw/pi-lsp"
    "npm:@narumitw/pi-plan-mode"
  ];
}
