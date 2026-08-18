{ ... }:
{
  programs.pi.coding-agent.settings.packages = [
    "npm:pi-subagents"
    "npm:pi-web-access"
    "npm:@narumitw/pi-lsp"
    "npm:@narumitw/pi-plan-mode"
  ];
}
