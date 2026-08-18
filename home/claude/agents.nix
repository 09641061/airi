{ lib, ... }:

let
  agentNames = [ "architect" "coordinator" "designer" "developer" "explorer" "researcher" "reviewer" "tester" ];

  # Per-agent model, defined in ./settings.nix.
  models = import ./settings.nix;

  findClosingFrontmatter = lines:
    if lines == [ ] then
      null
    else if builtins.head lines == "---" then
      0
    else
      let next = findClosingFrontmatter (builtins.tail lines);
      in if next == null then null else next + 1;

  splitAgent = agent:
    let
      lines = lib.splitString "\n" (builtins.readFile ../agents/${agent}.md);
      closingIndex =
        if lines != [ ] && builtins.head lines == "---" then
          findClosingFrontmatter (builtins.tail lines)
        else
          null;
      frontmatter = if closingIndex == null then [ ] else lib.sublist 1 closingIndex lines;
      body = if closingIndex == null then lines else lib.drop (closingIndex + 2) lines;
      descriptionLine = lib.findFirst (l: lib.hasPrefix "description:" l) null frontmatter;
      toolsLine = lib.findFirst (l: lib.hasPrefix "tools:" l) null frontmatter;
    in
    {
      description = lib.removePrefix "description:" descriptionLine;
      tools = if toolsLine == null then null else lib.removePrefix "tools:" toolsLine;
      body = lib.concatStringsSep "\n" body;
    };

  agentFile = agent:
    let
      parsed = splitAgent agent;
      toolsLine = lib.optionalString (parsed.tools != null) "tools:${parsed.tools}\n";
    in {
      name = ".claude/agents/${agent}.md";
      value.text = ''
        ---
        name: ${agent}
        description:${parsed.description}
        ${toolsLine}model: ${models.${agent}}
        ---
        ${parsed.body}
      '';
    };
in
{
  # Claude Code reads model per subagent from its own frontmatter field (see
  # settings.nix for the per-agent model map). The description is read from
  # the shared Markdown agents' own frontmatter, not duplicated here — these
  # files just add `model:` on top of what's already in home/agents/*.md.
  home.file = lib.listToAttrs (map agentFile agentNames);
}
