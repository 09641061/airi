{ pi, collie, ... }:
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
    (import ./home/herdr/collie.nix { inherit collie; })
    ./home/skills.nix
    pi.homeModules.default
  ];
}
