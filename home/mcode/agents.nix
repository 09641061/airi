{ ... }:

{
  # MiniMax Code reads project memory from the open `AGENTS.md` standard
  # at the repo root (see the built-in `init` skill), so the shared
  # per-role agent definitions live under the user-level data directory
  # at `~/.minimax/agents/`. From there they can be referenced as
  # subagents or imported by the project's own AGENTS.md.
  home.file = {
    ".minimax/agents/architect.md".source = ../agents/architect.md;
    ".minimax/agents/coordinator.md".source = ../agents/coordinator.md;
    ".minimax/agents/designer.md".source = ../agents/designer.md;
    ".minimax/agents/developer.md".source = ../agents/developer.md;
    ".minimax/agents/explorer.md".source = ../agents/explorer.md;
    ".minimax/agents/researcher.md".source = ../agents/researcher.md;
    ".minimax/agents/reviewer.md".source = ../agents/reviewer.md;
    ".minimax/agents/tester.md".source = ../agents/tester.md;
  };
}
