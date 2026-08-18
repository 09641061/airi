{ lib, ... }:

let
  agents = [ "architect" "coordinator" "designer" "developer" "explorer" "researcher" "reviewer" "tester" ];

  findClosingFrontmatter = lines:
    if lines == [ ] then
      null
    else if builtins.head lines == "---" then
      0
    else
      let next = findClosingFrontmatter (builtins.tail lines);
      in if next == null then null else next + 1;

  markdownBody = agent:
    let
      lines = lib.splitString "\n" (builtins.readFile ../agents/${agent}.md);
      withoutFrontmatter =
        if lines != [ ] && builtins.head lines == "---" then
          let closingIndex = findClosingFrontmatter (builtins.tail lines);
          in
          if closingIndex == null then
            lines
          else
            lib.drop (closingIndex + 2) lines
        else
          lines;
    in
    lib.concatStringsSep "\n" withoutFrontmatter;

  agentFile = agent: {
    name = ".codex/agents/${agent}.toml";
    value.text = ''
      name = "${agent}"
      description = "Shared ${agent} agent"
      developer_instructions = """
      ${markdownBody agent}
      """
    '';
  };
in
{
  # Codex requires TOML agents, so these files are generated from the shared
  # Markdown agents instead of maintaining a second copy of their prompts.
  home.file = lib.listToAttrs (map agentFile agents);
}
