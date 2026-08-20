{ lib, ... }:

let
  agentNames = [ "architect" "coordinator" "designer" "developer" "explorer" "researcher" "reviewer" "tester" ];

  # Per-agent model, defined in ./settings.nix.
  models = import ./settings.nix;

  # home/agents/*.md uses a generic lowercase tool vocabulary shared across
  # CLIs (pi, agy). Claude Code needs its own capitalized, built-in tool
  # names instead, so translate here; tokens with no Claude Code equivalent
  # (e.g. lsp_diagnostics, lsp_fix — no built-in LSP tool) are dropped
  # rather than left broken, which previously made agents spawn with zero
  # tools and get refused.
  toolNameMap = {
    read = "Read";
    bash = "Bash";
    edit = "Edit";
    write = "Write";
  };

  translateTools = toolsStr:
    let
      tokens = map lib.trim (lib.splitString "," (lib.removePrefix "\"" (lib.removeSuffix "\"" (lib.trim toolsStr))));
      mapped = builtins.filter (t: t != null) (map (t: toolNameMap.${t} or null) tokens);
    in
    lib.concatStringsSep "," mapped;

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
      translatedTools = lib.optionalString (parsed.tools != null) (translateTools parsed.tools);
      toolsLine = lib.optionalString (translatedTools != "") "tools: ${translatedTools}\n";
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
