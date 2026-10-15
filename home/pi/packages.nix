{ config, ... }:
let
  piVersion = config.programs.pi.coding-agent.package.version;
in
{
  programs.pi.coding-agent.settings.packages = [
    # Async subagents need the unbundled runtime alongside the standalone CLI.
    "npm:@earendil-works/pi-coding-agent@${piVersion}"
    # Client/server publish independently from the CLI, so pin their latest releases.
    "npm:@earendil-works/pi-client@1.1.0"
    "npm:@earendil-works/pi-server@1.1.0"
    "npm:pi-subagents@0.78.0"
    "npm:pi-web-access@0.40.0"
    "npm:pi-mcp-adapter@5.3.0"
    "npm:@narumitw/pi-lsp@0.49.9"
    "npm:@narumitw/pi-plan-mode@0.59.2"
  ];
}
