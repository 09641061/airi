# Per-subagent model for Claude Code. All agents use sonnet except explorer,
# which stays on haiku for its lighter, read-only fact-finding role.
#
# Plain data on purpose (not a home-manager module): Claude Code has no
# settings.json field for per-subagent model, it only reads `model:` from
# each subagent's own frontmatter. home/claude/agents.nix imports this map
# and bakes it into the frontmatter it generates.
{
  architect = "sonnet";
  coordinator = "sonnet";
  designer = "sonnet";
  developer = "sonnet";
  explorer = "haiku";
  researcher = "sonnet";
  reviewer = "sonnet";
  tester = "sonnet";
}
