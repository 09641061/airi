{ pi, ... }:
{
  imports = [
    ./home/claude/agents.nix
    ./home/agy/agents.nix
    ./home/agy/settings.nix
    ./home/codex/agents.nix
    ./home/codex/settings.nix
    ./home/pi/agents.nix
    ./home/pi/settings.nix
    ./home/pi/packages.nix
    ./home/herdr/settings.nix
    ./home/herdr/plugins.nix
    ./home/herdr/server.nix
    ./home/skills.nix
    pi.homeModules.default
  ];

  programs.herdr = {
    enable = true;
    plugins = [
      "AltanS/collie"
      "yankewei/herdr-focus-notify"
    ];
    server.enable = true;
    config.server = {
      headless_cols = 200;
      headless_rows = 50;
      manage_ssh_config = true;
    };
  };
}
